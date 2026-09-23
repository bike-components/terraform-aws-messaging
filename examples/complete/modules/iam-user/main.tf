# Minimal IAM user for the examples — stands in for a human or a service
# account, depending on whether create_access_key is set. Not part of the
# published module; it only exists so the two examples have something real
# to grant access to (an assumer for the role-assumption example, a service
# account with static keys for the direct-attachment one).

resource "aws_iam_user" "this" {
  name = var.name
  tags = var.tags
}

# Static credentials, for the service-account / direct-attachment case.
# Left off by default since every access key is a long-lived secret that
# ends up in state.
resource "aws_iam_access_key" "this" {
  count = var.create_access_key ? 1 : 0

  user = aws_iam_user.this.name
}
