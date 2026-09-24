# modules/sqs

Single-resource wrapper around `aws_sqs_queue`. Used by the root module
both for main queues and for DLQs (a DLQ is just another instance of this
module, named `<queue>-dlq`). Owns naming (`name`/`name_prefix` mutual
exclusivity, FIFO `.fifo` suffix handling) and nothing else — no
messaging-specific logic, no DLQ/redrive/IAM wiring (that's the root
module's job). See [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md)
at the repo root for how this fits into the rest of the module.

<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.66.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_sqs_queue.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_name"></a> [name](#input\_name) | Exact queue name. Mutually exclusive with name\_prefix; exactly one of the two must be set. | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for a provider-generated queue name. Mutually exclusive with name; exactly one of the two must be set. | `string` | `null` | no |
| <a name="input_fifo_queue"></a> [fifo\_queue](#input\_fifo\_queue) | Create a FIFO queue instead of standard. Required if name ends in ".fifo". | `bool` | `false` | no |
| <a name="input_content_based_deduplication"></a> [content\_based\_deduplication](#input\_content\_based\_deduplication) | Enable content-based deduplication. Only applies when fifo\_queue is true. | `bool` | `false` | no |
| <a name="input_visibility_timeout_seconds"></a> [visibility\_timeout\_seconds](#input\_visibility\_timeout\_seconds) | How long a message stays invisible to other consumers after being received. | `number` | `30` | no |
| <a name="input_message_retention_seconds"></a> [message\_retention\_seconds](#input\_message\_retention\_seconds) | How long an unconsumed message is retained before SQS deletes it. | `number` | `345600` | no |
| <a name="input_max_message_size"></a> [max\_message\_size](#input\_max\_message\_size) | Maximum message size in bytes SQS will accept. | `number` | `262144` | no |
| <a name="input_delay_seconds"></a> [delay\_seconds](#input\_delay\_seconds) | Time in seconds a newly sent message is delayed before it's available to receive. | `number` | `0` | no |
| <a name="input_receive_wait_time_seconds"></a> [receive\_wait\_time\_seconds](#input\_receive\_wait\_time\_seconds) | Wait time for long polling on ReceiveMessage calls. 0 disables long polling. | `number` | `0` | no |
| <a name="input_redrive_policy"></a> [redrive\_policy](#input\_redrive\_policy) | JSON redrive policy pointing at a DLQ (deadLetterTargetArn/maxReceiveCount). Null means no DLQ. | `string` | `null` | no |
| <a name="input_redrive_allow_policy"></a> [redrive\_allow\_policy](#input\_redrive\_allow\_policy) | JSON redrive-allow policy controlling which source queues may redrive into this queue. Only meaningful when this queue is itself a DLQ. | `string` | `null` | no |
| <a name="input_kms_master_key_id"></a> [kms\_master\_key\_id](#input\_kms\_master\_key\_id) | KMS key ID/ARN/alias for server-side encryption. Leave null for unencrypted. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the queue. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the created queue. |
| <a name="output_id"></a> [id](#output\_id) | ID (URL) of the created queue, as returned by the provider's id attribute. |
| <a name="output_name"></a> [name](#output\_name) | Name of the created queue. |
| <a name="output_url"></a> [url](#output\_url) | URL of the created queue. |
<!-- END_TF_DOCS -->
