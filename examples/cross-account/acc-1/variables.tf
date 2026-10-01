variable "region" {
  description = "Region of the topic. May differ from acc-2's region — the module creates the subscription in the topic's region (derived from the ARN)."
  type        = string
  default     = "eu-central-1"
}

variable "topic_name" {
  description = "Name of the FIFO topic. Must end in \".fifo\"."
  type        = string
  default     = "ex-messaging-cross-account-events.fifo"

  validation {
    condition     = endswith(var.topic_name, ".fifo")
    error_message = "topic_name must end in \".fifo\" (FIFO topic)."
  }
}

variable "subscriber_policy_json" {
  description = "The external_topic_policy_json output of acc-2 (STEP 2), merged into the topic policy in STEP 3. Leave null for the first apply (STEP 1)."
  type        = string
  default     = null
}
