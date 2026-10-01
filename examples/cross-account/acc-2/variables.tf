variable "region" {
  description = "Region of the queue. The subscription is created in the topic's region regardless (derived from topic_arn)."
  type        = string
  default     = "eu-central-1"
}

variable "topic_arn" {
  description = "ARN of acc-1's FIFO topic — the topic_arn output of ../acc-1 (STEP 1)."
  type        = string

  validation {
    condition     = endswith(var.topic_arn, ".fifo")
    error_message = "topic_arn must be a FIFO topic (\".fifo\" suffix) — a standard topic can't deliver to the FIFO queue."
  }
}
