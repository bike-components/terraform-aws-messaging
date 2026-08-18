locals {
  topic_name = (
    var.fifo_topic && var.name != null && !endswith(var.name, ".fifo")
    ? "${var.name}.fifo"
    : var.name
  )

  topic_name_prefix = var.name_prefix == null ? null : "${var.name_prefix}-"
}

resource "aws_sns_topic" "this" {
  name              = local.topic_name
  name_prefix       = local.topic_name_prefix
  fifo_topic        = var.fifo_topic
  kms_master_key_id = var.kms_master_key_id
  tags              = var.tags

  lifecycle {
    precondition {
      condition     = (var.name == null) != (var.name_prefix == null)
      error_message = "Only one of \"name\" or \"name_prefix\" may be set; leave both null to let the provider generate a name."
    }

    precondition {
      condition     = var.fifo_topic || var.name == null || !endswith(var.name, ".fifo")
      error_message = "\"name\" may only end with \".fifo\" when \"fifo_topic\" is true."
    }
  }
}
