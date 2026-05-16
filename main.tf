###############################################################################
# Root composition — applied once per environment (dev/test/staging/prod) via
# `terraform apply -var-file=envs/<env>.tfvars` with backend selected by
# `terraform init -backend-config=backend/<env>.hcl`.
#
# Add per-env resources (VPC, ECS, ECR, ALB, etc.) here or compose them
# from ./modules.
#
# (old-way comparison: same 2000-resource diff as PR #10, but with the
# github-script comment block instead of tfcmt.)
resource "aws_ssm_parameter" "dummy_load" {
  count = 2000

  name  = "/${var.environment}/dummy/test-${count.index}"
  type  = "String"
  value = "value-${count.index}"
  tags  = local.common_tags
}
###############################################################################
