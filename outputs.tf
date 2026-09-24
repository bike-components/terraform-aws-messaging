output "topic_arn" {
  description = "ARN of the topic, whether created by this module (create_topic) or passed in via external_topic_arn. Null if neither is set."
  value       = local.topic_arn
}

output "queue_arns" {
  description = "ARN of each queue, keyed by queue name."
  value       = { for k, q in module.queues : k => q.arn }
}

output "queue_urls" {
  description = "URL of each queue, keyed by queue name."
  value       = { for k, q in module.queues : k => q.url }
}

output "dlq_arns" {
  description = "ARN of each queue's DLQ, keyed by queue name. Only present for queues with create_dlq = true."
  value       = { for k, q in module.dlq : k => q.arn }
}

output "payload_bucket_name" {
  description = "Name of the large-payload offload bucket, or null if no queue has enable_large_payload_offload set."
  value       = local.enable_large_payload_offload ? module.payload_bucket[0].bucket_name : null
}

output "queue_tx_role_arns" {
  description = "ARN of each queue's dedicated transmitter role, keyed by queue name. Only present for queues with create_tx_role = true."
  value       = { for k, r in aws_iam_role.queue_tx : k => r.arn }
}

output "queue_rx_role_arns" {
  description = "ARN of each queue's dedicated receiver role, keyed by queue name. Only present for queues with create_rx_role = true."
  value       = { for k, r in aws_iam_role.queue_rx : k => r.arn }
}

output "topic_tx_role_arn" {
  description = "ARN of the topic's transmitter role, or null if create_topic_tx_role is false."
  value       = local.create_topic_tx_role ? aws_iam_role.topic_tx[0].arn : null
}

output "queue_tx_policy_arns" {
  description = "ARN of each queue's tx (send) permission policy, keyed by queue name. Present for queues with create_tx_role and/or create_tx_policy = true. Attach it directly to a user, group, or your own role for access that doesn't require sts:AssumeRole."
  value       = { for k, p in aws_iam_policy.queue_tx : k => p.arn }
}

output "queue_rx_policy_arns" {
  description = "ARN of each queue's rx (consume) permission policy, keyed by queue name. Present for queues with create_rx_role and/or create_rx_policy = true. Attach it directly to a user, group, or your own role for access that doesn't require sts:AssumeRole."
  value       = { for k, p in aws_iam_policy.queue_rx : k => p.arn }
}

output "topic_tx_policy_arn" {
  description = "ARN of the topic's publish permission policy, or null if neither create_topic_tx_role nor create_topic_tx_policy is set. Attach it directly to a user, group, or your own role for access that doesn't require sts:AssumeRole."
  value       = local.create_topic_tx_policy ? aws_iam_policy.topic_tx[0].arn : null
}
