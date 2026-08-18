variable "name_prefix" {
  description = "Prefix applied to every resource name created by this module, unless overridden per-resource (e.g. via a queue's name_override)."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ---------------------------------------------------------------------------
# Topic
# ---------------------------------------------------------------------------

variable "create_topic" {
  description = "Create an SNS topic. Mutually exclusive with external_topic_arn — exactly one of the two should be set."
  type        = bool
  default     = false
}

variable "external_topic_arn" {
  description = "ARN of an existing SNS topic to subscribe queues to, instead of creating one. Mutually exclusive with create_topic."
  type        = string
  default     = null
}

variable "topic_name" {
  description = "Name for the created topic (before prefixing). Ignored if create_topic is false."
  type        = string
  default     = "topic"
}

variable "fifo_topic" {
  type    = bool
  default = false
}

# ---------------------------------------------------------------------------
# Queue defaults — global fallback, overridable per queue.
# This is what lets you fix "chat limits" (visibility timeout, message size,
# retention...) once for the whole module and only override the outlier.
# ---------------------------------------------------------------------------

variable "default_queue_settings" {
  description = "Fallback SQS settings applied to every queue unless the queue sets its own value."
  type = object({
    visibility_timeout_seconds = optional(number, 30)
    message_retention_seconds  = optional(number, 345600) # 4 days
    max_message_size           = optional(number, 262144) # 256 KB, SQS hard cap
    delay_seconds               = optional(number, 0)
    receive_wait_time_seconds   = optional(number, 0)
    max_receive_count           = optional(number, 5)
  })
  default = {}
}

# ---------------------------------------------------------------------------
# Queues
# ---------------------------------------------------------------------------

variable "queues" {
  description = "Map of queues to create. Key is the logical name, used for prefixed naming unless name_override is set. Any *_seconds/size field left null falls back to default_queue_settings."
  type = map(object({
    name_override               = optional(string, null)
    fifo_queue                  = optional(bool, false)
    content_based_deduplication = optional(bool, false)

    visibility_timeout_seconds = optional(number, null)
    message_retention_seconds  = optional(number, null)
    max_message_size           = optional(number, null)
    delay_seconds               = optional(number, null)
    receive_wait_time_seconds   = optional(number, null)

    create_dlq        = optional(bool, false)
    max_receive_count = optional(number, null)

    # Pub/sub behavior
    subscribe_to_topic   = optional(bool, true)
    raw_message_delivery = optional(bool, true) # true = queue gets the raw payload, not wrapped in the SNS envelope
    filter_policy        = optional(string, null)
    filter_policy_scope  = optional(string, "MessageAttributes")

    # Large-payload handling (S3 bypass), opt-in per queue
    enable_large_payload_offload = optional(bool, false)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Large payload (S3) offload — for the "I know this payload will blow the
# 256KB SQS/SNS limit" case. See README for whether this belongs here.
# ---------------------------------------------------------------------------

variable "large_payload_bucket_name" {
  description = "Override for the offload bucket name. Defaults to '<name_prefix>-payloads'."
  type        = string
  default     = null
}

variable "large_payload_expiration_days" {
  description = "How long offloaded payload objects live in S3 before automatic expiration."
  type        = number
  default     = 7
}

# ---------------------------------------------------------------------------
# IAM — transmitter (producer) and receiver (consumer) identities
# ---------------------------------------------------------------------------

variable "create_iam_roles" {
  description = "Create assumable transmitter/receiver IAM roles. Set to false if you only want the IAM policies as outputs to attach to your own roles."
  type        = bool
  default     = true
}

variable "transmitter_principal_arns" {
  description = "IAM principal ARNs (roles/users/accounts) allowed to assume the transmitter role. Required if create_iam_roles is true."
  type        = list(string)
  default     = []
}

variable "receiver_principal_arns" {
  description = "IAM principal ARNs (roles/users/accounts) allowed to assume the receiver role. Required if create_iam_roles is true."
  type        = list(string)
  default     = []
}
