# 0004. IAM roles fall back to the account root principal when no trust ARN is supplied

Status: accepted
Date: 2026-09-23 (backfilled — reflects the structure already in place)

## Context

A queue's tx/rx role (and the topic's tx role) is created whenever the
caller sets `create_tx_role`/`create_rx_role`/`create_topic_tx_role`, but
the caller may not yet know the exact IAM principal ARN that should be
allowed to assume it — that principal (a not-yet-created application
role, a role in another AWS account) might not exist until a later
`terraform apply`, possibly in a different repo or team's state. Requiring
`tx_principal_arns`/`rx_principal_arns` to be non-empty before the role
can be created would force callers to sequence their applies around a
chicken-and-egg dependency.

## Decision

When `tx_principal_arns`/`rx_principal_arns`/`topic_tx_principal_arns` is
left empty (the default), the role's trust policy falls back to the AWS
account root ARN (`local.account_root_arn` in `locals.tf`) instead of a
real principal. The role and its permission policy are created
immediately either way; only the trust relationship is deferred.

## Alternatives considered

- **Require at least one principal ARN before creating the role** —
  rejected because it forces callers to know the consumer's ARN up front,
  reintroducing the sequencing problem this module is meant to avoid.
- **Leave the trust policy empty/invalid when no principal is given** —
  rejected: `aws_iam_role` requires a valid `assume_role_policy`, so this
  isn't actually available as an option without a dummy principal of some
  kind; account root is the least-surprising dummy.

## Consequences

This is deliberately *not* an open door: IAM is default-deny, so trusting
the account root does not let every principal in the account assume the
role — it only means the *account itself* is a valid trust anchor, and
nothing can actually call `sts:AssumeRole` on the role until a separate
IAM policy grants that specific permission to a specific principal (using
the ARN from `queue_tx_role_arns`/`queue_rx_role_arns`/
`topic_tx_role_arn` in the outputs — see the `examples/complete` example,
where `aws_iam_user_policy.orders_producer_assume` is exactly that
separate grant). The risk this trades away is a false sense of security
if a reader assumes "role exists" implies "someone can assume it" —
worth flagging in review whenever a role is created with an empty
principal list and no follow-up `sts:AssumeRole` grant is visible
anywhere in the same or a linked Terraform config.
