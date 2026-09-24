# modules/sns

Single-resource wrapper around `aws_sns_topic`. Owns naming
(`name`/`name_prefix` mutual exclusivity, FIFO `.fifo` suffix handling)
and nothing else — no messaging-specific logic. See
[`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md) at the repo root for
how this fits into the rest of the module.

<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.66.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_sns_topic.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_name"></a> [name](#input\_name) | Exact topic name. Mutually exclusive with name\_prefix; leave both null to let the provider generate a name. | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for a provider-generated topic name. Mutually exclusive with name. | `string` | `null` | no |
| <a name="input_fifo_topic"></a> [fifo\_topic](#input\_fifo\_topic) | Create a FIFO topic instead of standard. Required if name ends in ".fifo". | `bool` | `false` | no |
| <a name="input_kms_master_key_id"></a> [kms\_master\_key\_id](#input\_kms\_master\_key\_id) | KMS key ID/ARN/alias for server-side encryption. Leave null for unencrypted. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the topic. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the created topic. |
| <a name="output_name"></a> [name](#output\_name) | Name of the created topic. |
<!-- END_TF_DOCS -->
