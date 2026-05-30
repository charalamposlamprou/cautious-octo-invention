###############################################################################
# GitHub Actions → AWS via OIDC.
#
# The OIDC provider is account-wide and must exist exactly once per AWS
# account. To support multiple environments in the same AWS account, set
# create_oidc_provider=true in exactly one composition and let the others
# look it up via the data source.
###############################################################################

locals {
  oidc_url = "token.actions.githubusercontent.com"
}

data "tls_certificate" "github_oidc" {
  count = var.create_oidc_provider ? 1 : 0
  url   = "https://${local.oidc_url}"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://${local.oidc_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_oidc[0].certificates[length(data.tls_certificate.github_oidc[0].certificates) - 1].sha1_fingerprint]

  tags = var.tags
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://${local.oidc_url}"
}

locals {
  oidc_provider_arn = (
    var.create_oidc_provider
    ? aws_iam_openid_connect_provider.github[0].arn
    : data.aws_iam_openid_connect_provider.github[0].arn
  )

  full_subjects = [
    for s in var.subject_filters : "repo:${var.github_org}/${var.github_repo}:${s}"
  ]
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_url}:sub"
      values   = local.full_subjects
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = var.max_session_duration

  tags = merge(var.tags, {
    Name = var.role_name
  })
}

resource "aws_iam_role_policy" "inline" {
  name   = "${var.role_name}-inline"
  role   = aws_iam_role.this.id
  policy = var.role_policy_json
}
