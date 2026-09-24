variable "name" {
  description = "Exact queue name. Mutually exclusive with name_prefix; exactly one of the two must be set."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Prefix for a provider-generated queue name. Mutually exclusive with name; exactly one of the two must be set."
  type        = string
  default     = null
}

variable "fifo_queue" {
  description = "Create a FIFO queue instead of standard. Required if name ends in \".fifo\"."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication. Only applies when fifo_queue is true."
  type        = bool
  default     = false
}

variable "visibility_timeout_seconds" {
  description = "How long a message stays invisible to other consumers after being received."
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "How long an unconsumed message is retained before SQS deletes it."
  type        = number
  default     = 345600 # 4 days
}

variable "max_message_size" {
  description = "Maximum message size in bytes SQS will accept."
  type        = number
  default     = 262144 # 256 KB — SQS hard cap
}

variable "delay_seconds" {
  description = "Time in seconds a newly sent message is delayed before it's available to receive."
  type        = number
  default     = 0
}

variable "receive_wait_time_seconds" {
  description = "Wait time for long polling on ReceiveMessage calls. 0 disables long polling."
  type        = number
  default     = 0
}

variable "redrive_policy" {
  description = "JSON redrive policy pointing at a DLQ (deadLetterTargetArn/maxReceiveCount). Null means no DLQ."
  type        = string
  default     = null
}

variable "redrive_allow_policy" {
  description = "JSON redrive-allow policy controlling which source queues may redrive into this queue. Only meaningful when this queue is itself a DLQ."
  type        = string
  default     = null
}

variable "kms_master_key_id" {
  description = "KMS key ID/ARN/alias for server-side encryption. Leave null for unencrypted."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the queue."
  type        = map(string)
  default     = {}
}
