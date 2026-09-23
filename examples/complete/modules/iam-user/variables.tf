variable "name" {
  description = "IAM user name."
  type        = string
}

variable "create_access_key" {
  description = "Create a static access key/secret pair for this user, to demonstrate the direct-attachment (no role assumption) access pattern."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
