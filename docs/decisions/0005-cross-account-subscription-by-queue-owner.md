# 0005. Cross-account topics: the queue owner subscribes, the topic owner applies a grant rendered by this module

Status: proposed
Date: 2026-09-30

## Context

`external_topic_arn` lets queues subscribe to a topic this module didn't
create. When that topic belongs to another AWS account (and possibly
another region), two things have to happen: an `sqs` subscription has to
be created on the topic, and the queue has to accept deliveries from it.
The queue side is already handled (`aws_sqs_queue_policy.topic_publish`,
`aws:SourceArn` condition). The open questions were who creates the
subscription, how the foreign topic's policy gets the required grant,
and how the cross-region case is handled.

This module runs with the consumer account's credentials and can't
modify a resource policy in another account without a second provider.

## Decision

This module (the queue owner) creates the subscriptions, and outputs the
statements the topic owner must merge into their topic policy as
`external_topic_policy_json`. The module doesn't take a second provider
and doesn't write the foreign policy itself.

- AWS documents two cross-account SNS→SQS setups. When the *queue owner*
  subscribes, SNS needs no confirmation for the SQS endpoint. When the
  *topic owner* subscribes a foreign queue, the queue owner has to
  confirm the subscription out of band (read the confirmation message
  from the queue and call `ConfirmSubscription`), which doesn't fit a
  single `terraform apply`.
- The grant is `sns:Subscribe` for this account's root principal,
  conditioned on `sns:Protocol = sqs` and `sns:Endpoint` = exactly the
  subscribed queue ARNs. `sns:Publish` is added only when this module
  also creates the topic tx role/policy.
- The queue ARNs in the grant are predicted from resolved names, not read
  from `module.queues`, so the output is known at plan time and the topic
  owner can apply it before the first consumer apply.
- The subscription's region comes from the ARN and is passed to the
  provider-v6 `region` argument, so callers don't pass a provider alias.

## Alternatives considered

- **Topic owner creates the subscription** (module outputs queue ARNs
  only) — needs a manual/out-of-band confirmation step per queue, and
  splits the subscription (filter policy, raw delivery) away from the
  queue definition it belongs to.
- **Module takes a second `aws.topic_owner` provider and writes the topic
  policy itself** — requires credentials in both accounts in one
  configuration, which is rare in practice. `aws_sns_topic_policy` also
  owns the *entire* policy, so the module would overwrite statements the
  topic owner manages for other subscribers.
- **Grant `sns:Subscribe` to the whole account without conditions** —
  simpler to hand over, but lets anything in the consumer account
  subscribe any endpoint type (e.g. HTTP/email) to someone else's topic.
- **Build the grant from `module.queues[*].arn`** — exact rather than
  predicted, but unknown until the queues exist, so the topic owner
  couldn't apply it before the consumer's first apply. The consumer's
  apply would then fail on the subscriptions.
- **Require a provider alias for the topic's region** — it works, but
  it's more wiring for every caller and redundant now that provider v6
  has a per-resource `region`.

## Consequences

Cross-account setup takes two steps across two parties: the topic owner
merges the grant, then the consumer applies. Because the grant is known
at plan time, the consumer can read it from a saved plan
(`terraform show -json`) without applying anything first — see
`examples/cross-account` (`acc-1/` topic owner, `acc-2/` consumer). The predicted queue ARNs have to stay in sync with
`modules/sqs` naming (`.fifo` suffixing). If that naming changes, the
grant silently stops matching and Subscribe fails with an authorization
error.

`external_topic_arn` has to be known at plan time, which was already
true because it gates the subscription `for_each`. The grant uses the
consumer account root as its principal, which delegates to IAM in the
consumer account (same reasoning as ADR 0004). A future option is to
narrow it to the Terraform deploy role. KMS key-policy requirements for
encrypted topics/queues are documented in the README and not automated.
