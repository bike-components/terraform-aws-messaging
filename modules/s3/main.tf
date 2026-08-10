locals {

  bucket_prefix = var.bucket_prefix == null ? null : "${var.bucket_prefix}-"
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  bucket_prefix = local.bucket_prefix
  force_destroy = var.force_destroy
  tags          = var.tags

  lifecycle {
    precondition {
      condition     = var.bucket_name == null || var.bucket_prefix == null
      error_message = "Only one of \"bucket_name\" or \"bucket_prefix\" may be set; leave both null to let the provider generate a name."
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-offloaded-payloads"
    status = "Enabled"

    filter {}

    expiration {
      days = var.expiration_days
    }
  }
}
