# # ---------------------------------------------------------------------------
# # Transmitter: publish to the topic (or send directly to a queue) and,
# # if configured, drop oversized payloads into S3.
# # ---------------------------------------------------------------------------
#
# data "aws_iam_policy_document" "transmitter" {
#   dynamic "statement" {
#     for_each = local.topic_enabled ? [1] : []
#     content {
#       sid       = "PublishToTopic"
#       effect    = "Allow"
#       actions   = ["sns:Publish"]
#       resources = [local.topic_arn]
#     }
#   }
#
#   statement {
#     sid       = "SendToQueuesDirectly"
#     effect    = "Allow"
#     actions   = ["sqs:SendMessage"]
#     resources = [for k, q in module.queues : q.arn]
#   }
#
#   dynamic "statement" {
#     for_each = local.enable_large_payload_offload ? [1] : []
#     content {
#       sid       = "PutOffloadedPayloads"
#       effect    = "Allow"
#       actions   = ["s3:PutObject"]
#       resources = ["${module.payload_bucket[0].bucket_arn}/*"]
#     }
#   }
# }
#
# # ---------------------------------------------------------------------------
# # Receiver: consume from queues, inspect DLQs, and fetch offloaded payloads.
# # ---------------------------------------------------------------------------
#
# data "aws_iam_policy_document" "receiver" {
#   statement {
#     sid    = "ConsumeFromQueues"
#     effect = "Allow"
#     actions = [
#       "sqs:ReceiveMessage",
#       "sqs:DeleteMessage",
#       "sqs:GetQueueAttributes",
#       "sqs:ChangeMessageVisibility",
#     ]
#     resources = [for k, q in module.queues : q.arn]
#   }
#
#   dynamic "statement" {
#     for_each = length(local.dlq_queues) > 0 ? [1] : []
#     content {
#       sid    = "InspectDeadLetterQueues"
#       effect = "Allow"
#       actions = [
#         "sqs:ReceiveMessage",
#         "sqs:GetQueueAttributes",
#       ]
#       resources = [for k, q in module.dlq : q.arn]
#     }
#   }
#
#   dynamic "statement" {
#     for_each = local.enable_large_payload_offload ? [1] : []
#     content {
#       sid       = "GetOffloadedPayloads"
#       effect    = "Allow"
#       actions   = ["s3:GetObject"]
#       resources = ["${module.payload_bucket[0].bucket_arn}/*"]
#     }
#   }
# }
#
# resource "aws_iam_policy" "transmitter" {
#   name   = "${var.name_prefix}-messaging-transmitter"
#   policy = data.aws_iam_policy_document.transmitter.json
#   tags   = var.tags
# }
#
# resource "aws_iam_policy" "receiver" {
#   name   = "${var.name_prefix}-messaging-receiver"
#   policy = data.aws_iam_policy_document.receiver.json
#   tags   = var.tags
# }
#
# # ---------------------------------------------------------------------------
# # Assumable roles (optional — skip with create_iam_roles = false and attach
# # the two policies above to roles you manage elsewhere)
# # ---------------------------------------------------------------------------
#
# data "aws_iam_policy_document" "transmitter_assume" {
#   count = var.create_iam_roles ? 1 : 0
#
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "AWS"
#       identifiers = var.transmitter_principal_arns
#     }
#   }
# }
#
# data "aws_iam_policy_document" "receiver_assume" {
#   count = var.create_iam_roles ? 1 : 0
#
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "AWS"
#       identifiers = var.receiver_principal_arns
#     }
#   }
# }
#
# resource "aws_iam_role" "transmitter" {
#   count              = var.create_iam_roles ? 1 : 0
#   name               = "${var.name_prefix}-messaging-transmitter"
#   assume_role_policy = data.aws_iam_policy_document.transmitter_assume[0].json
#   tags               = var.tags
# }
#
# resource "aws_iam_role" "receiver" {
#   count              = var.create_iam_roles ? 1 : 0
#   name               = "${var.name_prefix}-messaging-receiver"
#   assume_role_policy = data.aws_iam_policy_document.receiver_assume[0].json
#   tags               = var.tags
# }
#
# resource "aws_iam_role_policy_attachment" "transmitter" {
#   count      = var.create_iam_roles ? 1 : 0
#   role       = aws_iam_role.transmitter[0].name
#   policy_arn = aws_iam_policy.transmitter.arn
# }
#
# resource "aws_iam_role_policy_attachment" "receiver" {
#   count      = var.create_iam_roles ? 1 : 0
#   role       = aws_iam_role.receiver[0].name
#   policy_arn = aws_iam_policy.receiver.arn
# }
