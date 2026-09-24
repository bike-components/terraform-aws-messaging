variable "name" {
  description = "Exact topic name. Mutually exclusive with name_prefix; leave both null to let the provider generate a name."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Prefix for a provider-generated topic name. Mutually exclusive with name."
  type        = string
  default     = null
}

variable "fifo_topic" {
  description = "Create a FIFO topic instead of standard. Required if name ends in \".fifo\"."
  type        = bool
  default     = false
}

variable "kms_master_key_id" {
  description = "KMS key ID/ARN/alias for server-side encryption. Leave null for unencrypted."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the topic."
  type        = map(string)
  default     = {}
}
