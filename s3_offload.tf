# Only created if at least one queue has enable_large_payload_offload = true.
# See README for the "does this belong here" discussion — this bundles the
# bucket for portfolio convenience; promote modules/s3 to its own repo the
# moment you need it outside this messaging context.

module "payload_bucket" {
  source = "./modules/s3"
  count  = local.enable_large_payload_offload ? 1 : 0

  bucket_name     = local.large_payload_bucket_name
  expiration_days = var.large_payload_expiration_days
  tags            = var.tags
}
