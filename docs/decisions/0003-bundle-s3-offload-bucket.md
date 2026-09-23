# 0003. Bundle the large-payload S3 bucket in this module instead of a separate repo

Status: accepted
Date: 2026-09-23 (backfilled — reflects the structure already in place)

## Context

SQS/SNS cap message size at 256 KB. The standard workaround (the AWS
"extended client library" pattern) is: producer PUTs the oversized payload
to S3 and publishes a small pointer message instead; consumer GETs the
payload from S3 using the pointer. `modules/s3` (versioning-free,
KMS-encrypted, lifecycle-expiring bucket with public access fully
blocked) has zero messaging-specific logic in it — it's a generic bucket
module. The question was whether it belongs in this repo at all, or
should be a standalone artifact-storage module referenced from outside.

## Decision

`modules/s3` stays nested in this repo, created only when at least one
queue sets `enable_large_payload_offload = true`
(`s3_offload.tf`, gated on `local.enable_large_payload_offload`). The
justification is that the *IAM* is messaging-specific even though the
bucket isn't: `iam.tf` grants a queue's tx role `s3:PutObject` and its rx
role `s3:GetObject`, scoped to this bucket, only when that specific queue
opted into offload. That coupling — not the bucket resource itself — is
what ties `modules/s3` to this module.

## Alternatives considered

- **Separate `terraform-aws-artifact-store` repo, referenced by ARN** —
  cleaner separation of concerns, but pushes the IAM wiring (which needs
  to know the bucket ARN to scope `s3:PutObject`/`s3:GetObject`) into
  either this module (needing a bucket ARN input plus still writing the
  IAM here) or the artifact-store module (which would then need to know
  about SQS tx/rx roles — worse coupling in the other direction).
- **Skip S3 offload entirely, leave it as an application-layer concern**
  — rejected because the IAM grant is exactly the kind of plumbing this
  module already exists to provide for every other cross-resource
  relationship (topic → queue delivery, queue → DLQ redrive).

## Consequences

Consumers who need large-payload offload get it "for free" with correct
least-privilege IAM, at the cost of this module owning a bucket resource
that has nothing to do with messaging semantics. The README documents an
explicit escape hatch: if the bucket is ever needed outside a messaging
context, promote `modules/s3` to its own top-level module the same way
`modules/sqs`/`modules/sns` could be promoted (see ADR 0001) — that's a
path change at the `source =` line, not a rewrite, because `modules/s3`
was kept free of messaging-specific logic from the start.
