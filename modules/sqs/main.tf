locals {
  queue_name = (
    var.fifo_queue && var.name != null && !endswith(var.name, ".fifo")
    ? "${var.name}.fifo"
    : var.name
  )

  queue_name_prefix = var.name_prefix == null ? null : "${var.name_prefix}-"
}

resource "aws_sqs_queue" "this" {
  name                        = local.queue_name
  name_prefix                 = local.queue_name_prefix
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  redrive_policy       = var.redrive_policy
  redrive_allow_policy = var.redrive_allow_policy

  kms_master_key_id = var.kms_master_key_id

  tags = var.tags

  lifecycle {
    precondition {
      condition     = (var.name == null) != (var.name_prefix == null)
      error_message = "Exactly one of \"name\" or \"name_prefix\" must be set."
    }

    precondition {
      condition     = var.fifo_queue || var.name == null || !endswith(var.name, ".fifo")
      error_message = "\"name\" may only end with \".fifo\" when \"fifo_queue\" is true."
    }
  }
}
