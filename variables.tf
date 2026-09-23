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
    delay_seconds              = optional(number, 0)
    receive_wait_time_seconds  = optional(number, 0)
    max_receive_count          = optional(number, 5)
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
    delay_seconds              = optional(number, null)
    receive_wait_time_seconds  = optional(number, null)

    create_dlq        = optional(bool, false)
    max_receive_count = optional(number, null)

    # Pub/sub behavior
    subscribe_to_topic   = optional(bool, true)
    raw_message_delivery = optional(bool, true) # true = queue gets the raw payload, not wrapped in the SNS envelope
    filter_policy        = optional(string, null)
    filter_policy_scope  = optional(string, "MessageAttributes")

    # Large-payload handling (S3 bypass), opt-in per queue
    enable_large_payload_offload = optional(bool, false)

    # IAM — opt this queue into its own dedicated tx (send) / rx (consume)
    # role. Independent of each other and of every other queue/topic.
    create_tx_role = optional(bool, false)
    create_rx_role = optional(bool, false)

    # Principals trusted to assume this queue's tx/rx role. Left empty (the
    # default), the role trusts the AWS account root instead — nobody can
    # actually assume it until something grants sts:AssumeRole on the role's
    # ARN, so this is a safe placeholder, not an open door.
    tx_principal_arns = optional(list(string), [])
    rx_principal_arns = optional(list(string), [])

    # Stand up the tx/rx permission set as a standalone, reusable IAM policy
    # (with its ARN in the module outputs) without also creating a role.
    # Use this to attach access straight to a user, group, or a role you
    # manage yourself — e.g. a service account authenticating with static
    # access keys, which has no way to call sts:AssumeRole against a role
    # created by create_tx_role/create_rx_role. Implied by create_tx_role /
    # create_rx_role, so you don't need to set both just to get a role.
    create_tx_policy = optional(bool, false)
    create_rx_policy = optional(bool, false)
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
#
# Every queue gets its own optional tx/rx role pair (see the `queues`
# variable above); the topic only ever gets a tx (publish) role, since
# consuming happens via the subscribed queues, not the topic itself.
# ---------------------------------------------------------------------------

variable "create_topic_tx_role" {
  description = "Create a dedicated IAM role that can publish to the topic. Ignored if no topic is created or configured (create_topic / external_topic_arn)."
  type        = bool
  default     = false
}

variable "create_topic_tx_policy" {
  description = "Stand up the topic's publish permission set as a standalone, reusable IAM policy (ARN in outputs) without also creating a role — for attaching straight to a user, group, or your own role. Implied by create_topic_tx_role. Ignored if no topic is created or configured."
  type        = bool
  default     = false
}

variable "topic_tx_principal_arns" {
  description = "Principals trusted to assume the topic's tx role. Left empty (the default), the role trusts the AWS account root instead — nobody can actually assume it until something grants sts:AssumeRole on the role's ARN."
  type        = list(string)
  default     = []
}
