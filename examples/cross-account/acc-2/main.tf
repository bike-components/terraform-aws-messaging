# ---------------------------------------------------------------------------
# Cross-account example — acc-2: the QUEUE OWNER (uses this module).
#
# One FIFO queue in this account subscribes to acc-1's FIFO topic. Following
# the AWS-recommended pattern, the queue owner creates the subscription, so
# SNS needs no confirmation handshake — but acc-1 must first allow it in its
# topic policy. The module can't write acc-1's policy, so it renders the
# required statement as the `external_topic_policy_json` output.
#
# Steps are numbered across BOTH directories — follow them in order,
# jumping between acc-1/main.tf and acc-2/main.tf:
#
#   STEP 1 (acc-1) create FIFO topic
#   STEP 2 (acc-2) render the grant (plan only)      ← this file
#   STEP 3 (acc-1) merge grant into topic policy
#   STEP 4 (acc-2) create queue + subscription       ← this file
#   STEP 5 (acc-1) publish a test message            ← README.md
#
# Exact commands: ../README.md.
# ---------------------------------------------------------------------------

provider "aws" {
  profile = "acc-2"
  region  = var.region
}

locals {
  tags = {
    Example    = "cross-account"
    Account    = "acc-2"
    Repository = "https://github.com/tomschinelli/terraform-aws-messaging"
  }
}

# ===========================================================================
# ===== STEP 2 (acc-2): render the grant for acc-1 — PLAN ONLY, no apply ====
#
# ----- WAIT: needs output `topic_arn` from acc-1 (STEP 1) ------------------
# In ../acc-1:  terraform output -raw topic_arn
# ---------------------------------------------------------------------------
#
# Do NOT apply yet: apply would create the subscription, and SNS rejects it
# (AuthorizationError) until acc-1 has merged the grant (STEP 3). The grant
# doesn't need the queue to exist — the module predicts the queue ARN from
# its name (incl. the ".fifo" suffix), so the output is already known in a
# plan. Extract it from a saved plan instead of state:
#
#   terraform init
#   terraform plan -var "topic_arn=<acc-1 topic_arn>" -out=grant.tfplan
#   terraform show -json grant.tfplan \
#     | jq -r '.planned_values.outputs.external_topic_policy_json.value' > grant.json
#
# Hand grant.json to acc-1 → continue with STEP 3 in ../acc-1/main.tf.
# ===========================================================================

# ===========================================================================
# ===== STEP 4 (acc-2): create the queue + subscription =====================
#
# ----- WAIT: acc-1 must have applied the grant (STEP 3) --------------------
# Check in ../acc-1:  terraform output topic_policy_json
#   → must contain the "AllowSubscribeFrom<acc-2 account id>" statement.
# ---------------------------------------------------------------------------
#
#   terraform apply -var "topic_arn=<acc-1 topic_arn>"
#
# Creates the FIFO queue, its queue policy (sns.amazonaws.com, SourceArn =
# acc-1's topic) and the subscription — in the topic's region, derived from
# the ARN. Then try STEP 5 from ../README.md.
# ===========================================================================

module "messaging" {
  source = "../../.."

  name_prefix = "ex-messaging-cross-account"

  # acc-1's topic. Being in another account is what makes the module emit
  # external_topic_policy_json; it must be a ".fifo" topic, since a standard
  # topic can't deliver to a FIFO queue.
  external_topic_arn = var.topic_arn

  # Exactly one queue, FIFO. The module appends ".fifo" to the resolved name
  # (ex-messaging-cross-account-events → ...-events.fifo), and the predicted
  # ARN in the grant uses the same suffix.
  queues = {
    events = {
      fifo_queue = true
      # subscribe_to_topic = true (default) — this is what puts the queue
      # ARN into the grant's sns:Endpoint condition.
    }
  }

  # Not set here: create_topic_tx_role / create_topic_tx_policy. Setting
  # either would add an sns:Publish statement for acc-2 to the grant.

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "external_topic_policy_json" {
  description = "STEP 2 → STEP 3: the statement acc-1 must merge into its topic policy (sns:Subscribe, sns:Protocol = sqs, sns:Endpoint = the queue ARN). Known at plan time."
  value       = module.messaging.external_topic_policy_json
}

output "queue_arn" {
  description = "ARN of the FIFO queue subscribed to acc-1's topic."
  value       = module.messaging.queue_arns["events"]
}

output "queue_url" {
  description = "URL of the FIFO queue — use it to receive the STEP 5 test message."
  value       = module.messaging.queue_urls["events"]
}
