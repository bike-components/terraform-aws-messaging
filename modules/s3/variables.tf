variable "bucket_name" {
  type    = string
  default = null
}

variable "bucket_prefix" {
  type    = string
  default = null
}

variable "expiration_days" {
  type    = number
  default = 7
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
