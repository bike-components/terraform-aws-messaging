locals {
  topic_name = "${var.name_prefix}-${var.topic_name}"

  # Merge each queue's own settings over the module-wide defaults, and
  # resolve its final prefixed name. Everything downstream reads from
  # local.queues instead of var.queues so overrides only have to be handled
  # once, here.
  queues = {
    for k, q in var.queues : k => merge(q, {
      resolved_name = coalesce(q.name_override, "${var.name_prefix}-${k}")

      visibility_timeout_seconds = coalesce(q.visibility_timeout_seconds, var.default_queue_settings.visibility_timeout_seconds)
      message_retention_seconds  = coalesce(q.message_retention_seconds, var.default_queue_settings.message_retention_seconds)
      max_message_size           = coalesce(q.max_message_size, var.default_queue_settings.max_message_size)
      delay_seconds               = coalesce(q.delay_seconds, var.default_queue_settings.delay_seconds)
      receive_wait_time_seconds   = coalesce(q.receive_wait_time_seconds, var.default_queue_settings.receive_wait_time_seconds)
      max_receive_count           = coalesce(q.max_receive_count, var.default_queue_settings.max_receive_count)
    })
  }

  dlq_queues     = { for k, q in local.queues : k => q if q.create_dlq }
  offload_queues = { for k, q in local.queues : k => q if q.enable_large_payload_offload }
  subscribed_queues = { for k, q in local.queues : k => q if q.subscribe_to_topic }

  topic_arn = var.create_topic ? module.topic[0].arn : var.external_topic_arn

  # Whether a topic is in play at all. Derived from the input variables rather
  # than local.topic_arn, which is unknown until apply when we create the
  # topic ourselves — for_each and count can't depend on that.
  topic_enabled = var.create_topic || var.external_topic_arn != null

  enable_large_payload_offload = length(local.offload_queues) > 0
  large_payload_bucket_name    = coalesce(var.large_payload_bucket_name, "${var.name_prefix}-payloads")
}
