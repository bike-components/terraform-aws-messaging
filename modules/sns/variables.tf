variable "name" {
  type    = string
  default = null
}

variable "name_prefix" {
  type    = string
  default = null
}

variable "fifo_topic" {
  type    = bool
  default = false
}

variable "kms_master_key_id" {
  description = "KMS key ID/ARN/alias for server-side encryption. Leave null for unencrypted."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
