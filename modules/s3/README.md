# modules/s3

Generic, messaging-agnostic S3 bucket: public access fully blocked,
SSE-KMS by default, and a single lifecycle rule that expires objects
after `expiration_days`. Has no messaging-specific logic — the root
module only wires it in for large-payload offload, and only the IAM
statements at the root know about queues. See
[`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md) at the repo root,
and [ADR 0003](../../docs/decisions/0003-bundle-s3-offload-bucket.md) for
why this bucket module lives in a messaging repo at all.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
