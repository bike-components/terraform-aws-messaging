# modules/sns

Single-resource wrapper around `aws_sns_topic`. Owns naming
(`name`/`name_prefix` mutual exclusivity, FIFO `.fifo` suffix handling)
and nothing else — no messaging-specific logic. See
[`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md) at the repo root for
how this fits into the rest of the module.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
