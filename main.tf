# ---------------------------------------------------------------------------
# Topic (optional — skipped entirely if you're subscribing to an external one)
# ---------------------------------------------------------------------------

module "topic" {
  source = "./modules/sns"
  count  = var.create_topic ? 1 : 0

  name                        = local.topic_name
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.topic_content_based_deduplication
  tags                        = var.tags
}

# ---------------------------------------------------------------------------
# Dead-letter queues — created first so main queues can reference their ARNs.
# Only created for queue entries with create_dlq = true.
# ---------------------------------------------------------------------------

module "dlq" {
  source   = "./modules/sqs"
  for_each = local.dlq_queues

  # A name_prefix queue gets an AWS-generated DLQ name too ('<prefix>-dlq-<random>').
  name                       = each.value.name_prefix == null ? "${trimsuffix(each.value.resolved_name, ".fifo")}-dlq" : null
  name_prefix                = each.value.name_prefix == null ? null : "${each.value.name_prefix}-dlq"
  fifo_queue                 = each.value.fifo_queue
  visibility_timeout_seconds = each.value.visibility_timeout_seconds
  message_retention_seconds  = each.value.message_retention_seconds
  max_message_size           = each.value.max_message_size

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Main queues
# ---------------------------------------------------------------------------

module "queues" {
  source   = "./modules/sqs"
  for_each = local.queues

  name                        = each.value.name_prefix == null ? each.value.resolved_name : null
  name_prefix                 = each.value.name_prefix
  fifo_queue                  = each.value.fifo_queue
  content_based_deduplication = each.value.content_based_deduplication

  visibility_timeout_seconds = each.value.visibility_timeout_seconds
  message_retention_seconds  = each.value.message_retention_seconds
  max_message_size           = each.value.max_message_size
  delay_seconds              = each.value.delay_seconds
  receive_wait_time_seconds  = each.value.receive_wait_time_seconds

  redrive_policy = each.value.create_dlq ? jsonencode({
    deadLetterTargetArn = module.dlq[each.key].arn
    maxReceiveCount     = each.value.max_receive_count
  }) : null

  tags = var.tags
}

# A queue is only allowed to redrive into a DLQ that explicitly permits it.
resource "aws_sqs_queue_redrive_allow_policy" "this" {
  for_each  = local.dlq_queues
  queue_url = module.dlq[each.key].url

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [module.queues[each.key].arn]
  })
}

# ---------------------------------------------------------------------------
# Pub/sub wiring — subscribe queues to the topic (created or external)
# ---------------------------------------------------------------------------

# For an external topic in another account, this subscription is created by
# the queue owner (this account) — the AWS-recommended direction, since SNS
# then needs no confirmation handshake for the SQS endpoint. It requires the
# topic owner to grant sns:Subscribe on their topic policy first; see the
# external_topic_policy_json output and docs/decisions/0005.
resource "aws_sns_topic_subscription" "this" {
  for_each = local.topic_enabled ? local.subscribed_queues : {}

  # Subscriptions live in the topic's region, not the queue's. Null (created
  # topic) falls back to the provider region.
  region = local.topic_region

  topic_arn            = local.topic_arn
  protocol             = "sqs"
  endpoint             = module.queues[each.key].arn
  raw_message_delivery = each.value.raw_message_delivery
  filter_policy        = each.value.filter_policy
  filter_policy_scope  = each.value.filter_policy != null ? each.value.filter_policy_scope : null
}

# Let the topic actually deliver into each subscribed queue.
resource "aws_sqs_queue_policy" "topic_publish" {
  for_each = local.topic_enabled ? local.subscribed_queues : {}

  queue_url = module.queues[each.key].url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSNSPublish"
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = module.queues[each.key].arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = local.topic_arn }
      }
    }]
  })
}
