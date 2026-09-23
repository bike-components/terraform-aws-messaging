# 0002. Per-queue/topic opt-in IAM roles instead of one blanket tx/rx role

Status: accepted
Date: 2026-09-23 (backfilled — reflects the structure already in place)

## Context

Producers and consumers need AWS credentials scoped to exactly the queues
they touch. A messaging module could offer a single "transmitter role"
that can publish to the topic and send to every queue, and a single
"receiver role" that can consume from every queue — simplest possible
surface, one role pair regardless of how many queues exist.

## Decision

There is no module-wide transmitter or receiver role. Each queue opts in
independently via `create_tx_role` / `create_rx_role` (`iam.tf`,
`locals.tf`'s `queue_tx` / `queue_rx` maps), and the topic only ever gets
a tx (publish) role via `create_topic_tx_role` — never a topic-level rx
role, since consuming always happens through a subscribed queue's own rx
role. A queue with neither flag set gets no IAM resources at all. The
underlying permission set is additionally available as a standalone
`aws_iam_policy` (`create_tx_policy` / `create_rx_policy`, implied by the
role flags) for callers who want to attach it directly to a user, group,
or their own role instead of assuming a module-created one.

## Alternatives considered

- **One blanket tx/rx role pair for the whole module** — rejected because
  it violates least privilege by construction: a producer that only needs
  to write to `orders` would, by default, also be able to write to
  `metrics`, `logs`, and every other queue in the module. There's no way
  to narrow it per-queue without turning it into per-queue roles anyway.
- **Always create both a role and a bare policy for every queue** —
  rejected as unnecessary IAM sprawl for the common case (most queues need
  neither); `create_tx_policy`/`create_rx_policy` exist as an explicit,
  separate opt-in for the static-credentials case instead.

## Consequences

Every queue and the topic needs explicit IAM opt-in, which is more
Terraform to write for a caller wiring up N queues with per-queue access,
but it means the blast radius of a compromised producer/consumer
credential is exactly the resources that queue's role names, not the
whole topology. Trust-policy defaults (falling back to the account root
when no principal ARN is supplied) are covered separately in ADR 0004.
