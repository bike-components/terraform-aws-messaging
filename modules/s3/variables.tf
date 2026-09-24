variable "bucket_name" {
  description = "Exact bucket name. Mutually exclusive with bucket_prefix; leave both null to let the provider generate a name."
  type        = string
  default     = null
}

variable "bucket_prefix" {
  description = "Prefix for a provider-generated bucket name. Mutually exclusive with bucket_name."
  type        = string
  default     = null
}

variable "expiration_days" {
  description = "How long objects live in the bucket before the lifecycle rule expires them."
  type        = number
  default     = 7
}

variable "force_destroy" {
  description = "Allow the bucket to be destroyed even if it still contains objects."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the bucket."
  type        = map(string)
  default     = {}
}
