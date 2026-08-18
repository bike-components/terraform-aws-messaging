variable "name" {
  type    = string
  default = null
}

variable "name_prefix" {
  type    = string
  default = null
}

variable "fifo_queue" {
  type    = bool
  default = false
}

variable "content_based_deduplication" {
  type    = bool
  default = false
}

variable "visibility_timeout_seconds" {
  type    = number
  default = 30
}

variable "message_retention_seconds" {
  type    = number
  default = 345600 # 4 days
}

variable "max_message_size" {
  type    = number
  default = 262144 # 256 KB — SQS hard cap
}

variable "delay_seconds" {
  type    = number
  default = 0
}

variable "receive_wait_time_seconds" {
  type    = number
  default = 0
}

variable "redrive_policy" {
  type    = string
  default = null
}

variable "redrive_allow_policy" {
  type    = string
  default = null
}

variable "kms_master_key_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
