###############################################################################
# Platform stack — bootstrap-once IAM resources that survive env teardowns.
#
# Why this composition exists separately:
#   When `terraform destroy` runs from CI against an env that *contains* its
#   own infra-apply role, terraform would delete the role mid-destroy → the
#   credentials it was using become invalid → all subsequent calls (incl.
#   state writes) fail with InvalidAccessKeyId. Classic chicken-and-egg.
#
#   Fix: keep the role used by `terraform destroy` in a separate state so
#   `destroy` against any env never touches it.
#
# What's here:
#  - The account-wide GitHub OIDC provider (one per AWS account).
#  - Four `*-github-infra` roles (dev/test/staging/prod) used by the main
#    terraform.yml plan/apply jobs.
#
# State:
#   Uses the LOCAL backend — this stack is bootstrapped once from a laptop
#   and the resulting state file (_platform/terraform.tfstate) is gitignored.
#   If you need to rotate trust policies later, run `terraform apply` from
#   the same machine, or store the state file in 1Password / a private
#   bucket between runs.
#
# Apply order:
#  1. From your laptop: `cd _platform && terraform init && terraform apply`.
#  2. Copy the role ARN outputs into the repo's GitHub Actions variables
#     (AWS_ROLE_DEV, AWS_ROLE_TEST, AWS_ROLE_STAGING, AWS_ROLE_PROD).
#  3. The root composition (../*.tf) then uses those roles to plan/apply
#     per-env via envs/<env>.tfvars + backend/<env>.hcl.
###############################################################################

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
  tags = local.common_tags
}

module "github_infra_role_dev" {
  source = "../modules/iam-oidc"

  create_oidc_provider = false
  github_org           = var.github_org
  github_repo          = var.github_repo
  role_name            = "${var.service_name}-dev-github-infra"
  role_policy_json     = data.aws_iam_policy_document.infra_apply.json
  max_session_duration = 7200

  subject_filters = [
    "environment:dev",
    "ref:refs/heads/*",
    "pull_request",
  ]

  tags = local.common_tags

  depends_on = [aws_iam_openid_connect_provider.github]
}

module "github_infra_role_test" {
  source = "../modules/iam-oidc"

  create_oidc_provider = false
  github_org           = var.github_org
  github_repo          = var.github_repo
  role_name            = "${var.service_name}-test-github-infra"
  role_policy_json     = data.aws_iam_policy_document.infra_apply.json
  max_session_duration = 7200

  subject_filters = [
    "environment:test",
    "ref:refs/heads/*",
    "pull_request",
  ]

  tags = local.common_tags

  depends_on = [aws_iam_openid_connect_provider.github]
}

module "github_infra_role_staging" {
  source = "../modules/iam-oidc"

  create_oidc_provider = false
  github_org           = var.github_org
  github_repo          = var.github_repo
  role_name            = "${var.service_name}-staging-github-infra"
  role_policy_json     = data.aws_iam_policy_document.infra_apply.json
  max_session_duration = 7200

  subject_filters = [
    "environment:staging",
    "ref:refs/heads/master",
  ]

  tags = local.common_tags

  depends_on = [aws_iam_openid_connect_provider.github]
}

module "github_infra_role_prod" {
  source = "../modules/iam-oidc"

  create_oidc_provider = false
  github_org           = var.github_org
  github_repo          = var.github_repo
  role_name            = "${var.service_name}-prod-github-infra"
  role_policy_json     = data.aws_iam_policy_document.infra_apply.json
  max_session_duration = 7200

  subject_filters = [
    "environment:production",
    "ref:refs/heads/master",
  ]

  tags = local.common_tags

  depends_on = [aws_iam_openid_connect_provider.github]
}
