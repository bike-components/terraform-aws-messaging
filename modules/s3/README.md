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


## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.66.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Exact bucket name. Mutually exclusive with bucket\_prefix; leave both null to let the provider generate a name. | `string` | `null` | no |
| <a name="input_bucket_prefix"></a> [bucket\_prefix](#input\_bucket\_prefix) | Prefix for a provider-generated bucket name. Mutually exclusive with bucket\_name. | `string` | `null` | no |
| <a name="input_expiration_days"></a> [expiration\_days](#input\_expiration\_days) | How long objects live in the bucket before the lifecycle rule expires them. | `number` | `7` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow the bucket to be destroyed even if it still contains objects. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the created bucket. |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the created bucket. |
<!-- END_TF_DOCS -->
