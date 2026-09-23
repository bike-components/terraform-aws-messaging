# modules/sqs

Single-resource wrapper around `aws_sqs_queue`. Used by the root module
both for main queues and for DLQs (a DLQ is just another instance of this
module, named `<queue>-dlq`). Owns naming (`name`/`name_prefix` mutual
exclusivity, FIFO `.fifo` suffix handling) and nothing else — no
messaging-specific logic, no DLQ/redrive/IAM wiring (that's the root
module's job). See [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md)
at the repo root for how this fits into the rest of the module.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
