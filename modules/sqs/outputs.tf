output "arn" {
  description = "ARN of the created queue."
  value       = aws_sqs_queue.this.arn
}

output "id" {
  description = "ID (URL) of the created queue, as returned by the provider's id attribute."
  value       = aws_sqs_queue.this.id
}

output "name" {
  description = "Name of the created queue."
  value       = aws_sqs_queue.this.name
}

output "url" {
  description = "URL of the created queue."
  value       = aws_sqs_queue.this.url
}
