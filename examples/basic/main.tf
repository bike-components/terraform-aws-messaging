provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  region = "eu-central-1"
  name   = "ex-messaging-${basename(path.cwd)}"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/tomschinelli/terraform-aws-messaging"
  }
}


module "complete" {
  source = "../../"

  name_prefix = local.name

  create_topic = true
  topic_name   = "events"


  queues = {
    orders = {
      create_dlq = true
    }
    metrics = {
      create_dlq         = true
      max_receive_count  = 3   # overrides the module default above
      raw_message_delivery = false
    }
    logs = {
      # no DLQ, module-default limits apply
      enable_large_payload_offload = true
    }
    audit = {
      name_override      = "compliance-audit-queue" # ignores the prefix entirely
      subscribe_to_topic = false                     # direct-send only, not part of pub/sub
    }
  }
  tags = local.tags
}
