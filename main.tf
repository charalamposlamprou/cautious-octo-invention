###############################################################################
# Root composition — applied once per environment (dev/test/staging/prod) via
# `terraform apply -var-file=envs/<env>.tfvars` with backend selected by
# `terraform init -backend-config=backend/<env>.hcl`.
#
# Add per-env resources (VPC, ECS, ECR, ALB, etc.) here or compose them
# from ./modules.
#
# (dummy-tfcmt: verify tfcmt plan + apply comments end-to-end on a fresh PR.)

# 2000 dummy SSM parameters to force a large plan diff and stress tfcmt
# rendering / GitHub PR-comment truncation. Names are namespaced per env so
# dev/test don't collide on the same SSM keys in the shared AWS account.
resource "aws_ssm_parameter" "dummy_load" {
  count = 2000

  name  = "/${var.environment}/dummy/test-${count.index}"
  type  = "String"
  value = "value-${count.index}"
  tags  = local.common_tags
}
###############################################################################
