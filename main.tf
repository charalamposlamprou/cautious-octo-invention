###############################################################################
# Root composition — applied once per environment (dev/test/staging/prod) via
# `terraform apply -var-file=envs/<env>.tfvars` with backend selected by
# `terraform init -backend-config=backend/<env>.hcl`.
#
# Add per-env resources (VPC, ECS, ECR, ALB, etc.) here or compose them
# from ./modules.

###############################################################################
# Dummy resources — small, cheap, namespaced per env. Replace as real
# infrastructure is added.
###############################################################################

resource "aws_ssm_parameter" "app_config" {
  name  = "/${var.environment}/app/config"
  type  = "String"
  value = jsonencode({ greeting = "hello from ${var.environment}" })
  tags  = local.common_tags
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.environment}/app"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_s3_bucket" "app" {
  bucket = "${local.name_prefix}-app-${data.aws_caller_identity.current.account_id}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket                  = aws_s3_bucket.app.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "current" {}
###############################################################################
