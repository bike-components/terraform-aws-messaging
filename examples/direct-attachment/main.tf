# ---------------------------------------------------------------------------
# Direct-attachment example — access is granted straight to a service
# account's static access keys, with no assume-role step. Useful when the
# caller can't (or shouldn't have to) call sts:AssumeRole — e.g. a legacy
# app or a third-party tool that's only ever configured with an access
# key/secret pair.
#
# The module exposes each tx/rx permission set as a standalone, reusable
# IAM policy ARN (via create_tx_policy/create_rx_policy) whether or not a
# role is also created. This example attaches those policies directly to
# an IAM user instead of creating any role.
#
# See ../complete for the alternative: assumable roles trusted by specific
# principals.
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

# The service account: a single IAM user with a static access key/secret,
# standing in for e.g. an on-prem app that authenticates with long-lived
# credentials instead of assuming a role.
module "orders_service_account" {
  source = "../complete/modules/iam-user"

  name              = "${local.name}-orders-service-account"
  create_access_key = true
  tags              = local.tags
}

module "complete" {
  source = "../../"

  name_prefix = local.name

  create_topic = true
  topic_name   = "events"

  queues = {
    orders = {
      create_dlq = true

      # No create_tx_role/create_rx_role — just the standalone policies,
      # attached below directly to the service account below.
      create_tx_policy = true
      create_rx_policy = true
    }
  }
  tags = local.tags
}

# Grant the service account's access key send/receive access immediately —
# no sts:AssumeRole call needed, unlike the role-assumption example.
resource "aws_iam_user_policy_attachment" "orders_tx" {
  user       = module.orders_service_account.name
  policy_arn = module.complete.queue_tx_policy_arns["orders"]
}

resource "aws_iam_user_policy_attachment" "orders_rx" {
  user       = module.orders_service_account.name
  policy_arn = module.complete.queue_rx_policy_arns["orders"]
}
