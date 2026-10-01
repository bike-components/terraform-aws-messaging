# ---------------------------------------------------------------------------
# Cross-account example — acc-1: the TOPIC OWNER.
#
# This account owns the FIFO SNS topic. It does NOT use this module: in a
# real setup the topic usually belongs to another team that manages it with
# plain resources. Its only job beyond creating the topic is to merge the
# grant that acc-2 (the queue owner, which DOES use the module) hands over.
#
#   acc-1 (this dir, topic owner)              acc-2 (../acc-2, queue owner)
#   ┌───────────────────────────────┐          ┌──────────────────────────────┐
#   │ FIFO SNS topic                │─deliver─▶│ FIFO SQS queue (module)      │
#   │ topic policy                  │          │ subscription (module)        │
#   │   + external_topic_policy_json│◀─ grant ─┤ output external_topic_policy │
#   └───────────────────────────────┘          └──────────────────────────────┘
#
# Steps are numbered across BOTH directories — follow them in order,
# jumping between acc-1/main.tf and acc-2/main.tf:
#
#   STEP 1 (acc-1) create FIFO topic                 ← this file
#   STEP 2 (acc-2) render the grant (plan only)
#   STEP 3 (acc-1) merge grant into topic policy     ← this file
#   STEP 4 (acc-2) create queue + subscription
#   STEP 5 (acc-1) publish a test message            ← README.md
#
# Exact commands: ../README.md.
# ---------------------------------------------------------------------------

provider "aws" {
  profile = "acc-1"
  region  = var.region
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  tags = {
    Example    = "cross-account"
    Account    = "acc-1"
    Repository = "https://github.com/tomschinelli/terraform-aws-messaging"
  }
}

# ===========================================================================
# ===== STEP 1 (acc-1): create the FIFO topic ===============================
#
#   terraform init && terraform apply
#
# First apply: var.subscriber_policy_json is still null, so the topic policy
# below contains only the owner's own statement. Then hand the `topic_arn`
# output to acc-2 → continue with STEP 2 in ../acc-2/main.tf.
# ===========================================================================

resource "aws_sns_topic" "events" {
  # FIFO topics must end in ".fifo". Content-based dedup lets publishers
  # skip MessageDeduplicationId (handy for the STEP 5 test message).
  name                        = var.topic_name
  fifo_topic                  = true
  content_based_deduplication = true
  tags                        = local.tags
}

# ===========================================================================
# ===== STEP 3 (acc-1): merge acc-2's grant into the topic policy ===========
#
# ----- WAIT: needs output `external_topic_policy_json` from acc-2 (STEP 2) --
# acc-2 cannot subscribe its queue until this policy allows it, and acc-2
# can only render the grant once it knows the topic ARN from STEP 1.
# In ../acc-2, STEP 2 wrote the grant to ../acc-2/grant.json. Then, here:
#
#   terraform apply -var "subscriber_policy_json=$(cat ../acc-2/grant.json)"
#
# Then continue with STEP 4 in ../acc-2/main.tf.
# ---------------------------------------------------------------------------
#
# (On the STEP 1 apply this same code runs with subscriber_policy_json =
# null — compact() drops it and the policy is owner-only.)
# ===========================================================================

data "aws_iam_policy_document" "topic" {
  # acc-2's grant: sns:Subscribe for exactly acc-2's queue ARN, restricted
  # to sns:Protocol = sqs. Merged in, not replacing the owner's statements.
  source_policy_documents = compact([var.subscriber_policy_json])

  # aws_sns_topic_policy owns the WHOLE policy, so the topic owner's own
  # access has to be restated alongside any grant handed over by others.
  statement {
    sid    = "TopicOwnerAccess"
    effect = "Allow"
    actions = [
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:AddPermission",
      "sns:RemovePermission",
      "sns:DeleteTopic",
      "sns:Subscribe",
      "sns:ListSubscriptionsByTopic",
      "sns:Publish",
    ]
    resources = [aws_sns_topic.events.arn]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_sns_topic_policy" "events" {
  arn    = aws_sns_topic.events.arn
  policy = data.aws_iam_policy_document.topic.json
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "topic_arn" {
  description = "ARN of the FIFO topic. Hand this to acc-2 (STEP 2 / STEP 4: -var topic_arn=...)."
  value       = aws_sns_topic.events.arn
}

output "topic_policy_json" {
  description = "Effective topic policy — after STEP 3 it should contain acc-2's AllowSubscribeFrom<acc-2 id> statement."
  value       = aws_sns_topic_policy.events.policy
}
