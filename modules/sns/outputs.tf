output "arn" {
  description = "ARN of the created topic."
  value       = aws_sns_topic.this.arn
}

output "name" {
  description = "Name of the created topic."
  value       = aws_sns_topic.this.name
}
