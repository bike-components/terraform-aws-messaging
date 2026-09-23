# 0001. Split SNS, SQS, and S3 into nested submodules instead of one flat module

Status: accepted
Date: 2026-09-23 (backfilled — reflects the structure already in place)

## Context

The root module needs to create an optional SNS topic, an arbitrary number
of SQS queues (each with its own optional DLQ), and an optional S3 bucket
for large-payload offload. All three resource types share naming,
tagging, and FIFO-suffix conventions. The root module also needs to loop
over a `queues` map with `for_each`, creating one queue and one DLQ per
map entry.

## Decision

Each AWS primitive gets its own single-resource nested module
(`modules/sns`, `modules/sqs`, `modules/s3`), each taking a flat set of
inputs (`name`, `name_prefix`, FIFO flags, etc.) and owning only its own
naming/validation logic (e.g. `modules/sqs` enforces that `name` XOR
`name_prefix` is set, and that a `.fifo` suffix is only allowed alongside
`fifo_queue = true`). The root module composes these with `for_each` and
wires the cross-resource plumbing (redrive policies, subscriptions, IAM)
at the root level.

## Alternatives considered

- **One flat module with all resources inline** — simpler to read for a
  small module, but the per-resource validation logic (name/name_prefix
  precondition, FIFO suffix precondition) would have to be duplicated or
  awkwardly parameterized for both SNS and SQS inline, and the module
  couldn't be tested or reasoned about one resource type at a time.
- **Publish `modules/sqs`/`modules/sns`/`modules/s3` as separate top-level
  repos from day one** — premature; nothing outside this messaging
  context consumes them yet. The nested-module boundary is kept clean
  enough (`source = "./modules/sqs"`, flat inputs, no messaging-specific
  logic inside) that promoting one to its own repo later is a path change,
  not a rewrite.

## Consequences

Adding a fourth AWS primitive (e.g. an EventBridge bus) follows the same
pattern: a new `modules/<name>` with flat inputs, composed at the root.
The tradeoff is one extra level of indirection when reading the root
module — `module.queues[each.key].arn` instead of a bare resource
reference — which is judged worth it for the validation/testability
split. See the README's "does this belong here" discussion for the same
reasoning applied to `modules/s3` specifically (0003).
