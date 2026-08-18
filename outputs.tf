output "topic_arn" {
  value = local.topic_arn
}

output "queue_arns" {
  value = { for k, q in module.queues : k => q.arn }
}

output "queue_urls" {
  value = { for k, q in module.queues : k => q.url }
}

output "dlq_arns" {
  value = { for k, q in module.dlq : k => q.arn }
}

output "payload_bucket_name" {
  value = local.enable_large_payload_offload ? module.payload_bucket[0].bucket_name : null
}

# output "transmitter_role_arn" {
#   value = var.create_iam_roles ? aws_iam_role.transmitter[0].arn : null
# }
#
# output "receiver_role_arn" {
#   value = var.create_iam_roles ? aws_iam_role.receiver[0].arn : null
# }
#
# output "transmitter_policy_arn" {
#   value = aws_iam_policy.transmitter.arn
# }
#
# output "receiver_policy_arn" {
#   value = aws_iam_policy.receiver.arn
# }
