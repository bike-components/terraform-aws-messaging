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


module "sns" {
  source      = "../../modules/sns"
  name = local.name
  fifo_topic  = true
  tags        = local.tags
}

module "s3" {
  source        = "../../modules/s3"
  bucket_prefix = local.name

  tags = local.tags
}
