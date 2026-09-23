# ---------------------------------------------------------------------------
# Transmitter (producer) and receiver (consumer) access.
#
# Each queue (and the topic, tx-only) opts into its own tx/rx permission
# policy independently, via create_tx_policy/create_rx_policy (or the
# *_role variants below, which imply the policy). A queue with none of
# those flags set simply gets no IAM resources.
#
# The permission policy is always a standalone, reusable aws_iam_policy —
# its ARN is in the outputs so it can be attached directly to a user,
# group, or a role you manage yourself (e.g. a service account using
# static access keys, which has no way to call sts:AssumeRole). The role
# below is an optional convenience on top of that same policy, for callers
# that want something assumable instead.
# ---------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# ---------------------------------------------------------------------------
# Per-queue transmitters — direct sqs:SendMessage, plus s3:PutObject when
# that queue has large-payload offload enabled.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "queue_tx" {
  for_each = local.queue_tx_policy

  statement {
    sid       = "SendToQueue"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [module.queues[each.key].arn]
  }

  dynamic "statement" {
    for_each = each.value.enable_large_payload_offload ? [1] : []
    content {
      sid       = "PutOffloadedPayloads"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${module.payload_bucket[0].bucket_arn}/*"]
    }
  }
}

resource "aws_iam_policy" "queue_tx" {
  for_each = local.queue_tx_policy

  name   = "${each.value.resolved_name}-tx"
  policy = data.aws_iam_policy_document.queue_tx[each.key].json
  tags   = var.tags
}

data "aws_iam_policy_document" "queue_tx_assume" {
  for_each = local.queue_tx

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = each.value.trusted_principal_arns
    }
  }
}

resource "aws_iam_role" "queue_tx" {
  for_each = local.queue_tx

  name               = "${each.value.resolved_name}-tx"
  assume_role_policy = data.aws_iam_policy_document.queue_tx_assume[each.key].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "queue_tx" {
  for_each = local.queue_tx

  role       = aws_iam_role.queue_tx[each.key].name
  policy_arn = aws_iam_policy.queue_tx[each.key].arn
}

# ---------------------------------------------------------------------------
# Per-queue receivers — consume from the queue, inspect its DLQ if it has
# one, plus s3:GetObject when that queue has large-payload offload enabled.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "queue_rx" {
  for_each = local.queue_rx_policy

  statement {
    sid    = "ConsumeFromQueue"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [module.queues[each.key].arn]
  }

  dynamic "statement" {
    for_each = each.value.create_dlq ? [1] : []
    content {
      sid    = "InspectDeadLetterQueue"
      effect = "Allow"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:GetQueueAttributes",
      ]
      resources = [module.dlq[each.key].arn]
    }
  }

  dynamic "statement" {
    for_each = each.value.enable_large_payload_offload ? [1] : []
    content {
      sid       = "GetOffloadedPayloads"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${module.payload_bucket[0].bucket_arn}/*"]
    }
  }
}

resource "aws_iam_policy" "queue_rx" {
  for_each = local.queue_rx_policy

  name   = "${each.value.resolved_name}-rx"
  policy = data.aws_iam_policy_document.queue_rx[each.key].json
  tags   = var.tags
}

data "aws_iam_policy_document" "queue_rx_assume" {
  for_each = local.queue_rx

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = each.value.trusted_principal_arns
    }
  }
}

resource "aws_iam_role" "queue_rx" {
  for_each = local.queue_rx

  name               = "${each.value.resolved_name}-rx"
  assume_role_policy = data.aws_iam_policy_document.queue_rx_assume[each.key].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "queue_rx" {
  for_each = local.queue_rx

  role       = aws_iam_role.queue_rx[each.key].name
  policy_arn = aws_iam_policy.queue_rx[each.key].arn
}

# ---------------------------------------------------------------------------
# Topic transmitter — sns:Publish only. Consuming happens via the subscribed
# queues' own rx policies/roles, so there's no topic rx side.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "topic_tx" {
  count = local.create_topic_tx_policy ? 1 : 0

  statement {
    sid       = "PublishToTopic"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [local.topic_arn]
  }
}

resource "aws_iam_policy" "topic_tx" {
  count = local.create_topic_tx_policy ? 1 : 0

  name   = "${local.topic_name}-tx"
  policy = data.aws_iam_policy_document.topic_tx[0].json
  tags   = var.tags
}

data "aws_iam_policy_document" "topic_tx_assume" {
  count = local.create_topic_tx_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = local.topic_tx_trusted_arns
    }
  }
}

resource "aws_iam_role" "topic_tx" {
  count = local.create_topic_tx_role ? 1 : 0

  name               = "${local.topic_name}-tx"
  assume_role_policy = data.aws_iam_policy_document.topic_tx_assume[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "topic_tx" {
  count = local.create_topic_tx_role ? 1 : 0

  role       = aws_iam_role.topic_tx[0].name
  policy_arn = aws_iam_policy.topic_tx[0].arn
}
