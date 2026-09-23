# ---------------------------------------------------------------------------
# Role-assumption example — access is granted through assumable IAM roles.
# A principal (here, a couple of demo IAM users) has to call sts:AssumeRole
# to get temporary credentials before it can send/receive anything.
#
# See ../direct-attachment for the alternative: granting a service account's
# static access keys permission directly, with no assume-role step.
# ---------------------------------------------------------------------------

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

# Demo principals allowed to assume the tx/rx roles below. In a real setup
# these would already exist (a human's IAM user, an application's role,
# even a role/user in another AWS account — cross-account works the same
# way, you'd just reference that account's ARN here instead of creating it).
module "orders_producer" {
  source = "./modules/iam-user"

  name = "${local.name}-orders-producer"
  tags = local.tags
}

module "orders_consumer" {
  source = "./modules/iam-user"

  name = "${local.name}-orders-consumer"
  tags = local.tags
}

module "complete" {
  source = "../../"

  name_prefix = local.name

  create_topic = true
  topic_name   = "events"

  # Dedicated role that can publish to the topic, scoped to one named user
  # instead of falling back to the account root.
  create_topic_tx_role    = true
  topic_tx_principal_arns = [module.orders_producer.arn]

  queues = {
    orders = {
      create_dlq = true

      # Only orders-producer can assume the role that sends to this queue.
      create_tx_role    = true
      tx_principal_arns = [module.orders_producer.arn]

      # Only orders-consumer can assume the role that reads from this queue.
      create_rx_role    = true
      rx_principal_arns = [module.orders_consumer.arn]
    }
    metrics = {
      create_dlq           = true
      max_receive_count    = 3 # overrides the module default above
      raw_message_delivery = false
    }
    logs = {
      # no DLQ, module-default limits apply
      enable_large_payload_offload = true
    }
    audit = {
      name_override      = "compliance-audit-queue" # ignores the prefix entirely
      subscribe_to_topic = false                    # direct-send only, not part of pub/sub
    }
  }
  tags = local.tags
}

# Let orders-producer/orders-consumer actually assume their respective
# roles — trusting a principal (iam.tf) only grants the *ability to ask*;
# the principal also needs sts:AssumeRole permission on the role's ARN.
resource "aws_iam_user_policy" "orders_producer_assume" {
  name = "${local.name}-assume-orders-tx"
  user = module.orders_producer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = module.complete.queue_tx_role_arns["orders"]
    }]
  })
}

resource "aws_iam_user_policy" "orders_consumer_assume" {
  name = "${local.name}-assume-orders-rx"
  user = module.orders_consumer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = module.complete.queue_rx_role_arns["orders"]
    }]
  })
}
