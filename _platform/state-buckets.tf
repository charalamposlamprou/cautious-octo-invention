###############################################################################
# S3 buckets for per-env Terraform state.
#
# One bucket per env (clean blast radius) with versioning, SSE, and full
# public-access block. Locking uses Terraform 1.10's S3-native lockfile
# (`use_lockfile = true` in each env's backend) so no DynamoDB table needed.
#
# Bucket name pattern: <service>-tfstate-<env>-<account_id>. Account ID is
# appended for global S3 uniqueness without leaking the org/team name.
###############################################################################

data "aws_caller_identity" "current" {}

locals {
  state_envs = ["dev", "test", "staging", "prod"]
}

resource "aws_s3_bucket" "state" {
  for_each = toset(local.state_envs)

  bucket = "${var.service_name}-tfstate-${each.key}-${data.aws_caller_identity.current.account_id}"

  # WARNING: force_destroy=true allows terraform destroy to empty and delete these
  # buckets including all versioned state objects. Set to false in long-lived
  # environments where accidental state loss is unacceptable.
  force_destroy = true

  tags = merge(local.common_tags, {
    Environment = each.key
    Purpose     = "terraform-state"
  })
}

resource "aws_s3_bucket_versioning" "state" {
  for_each = aws_s3_bucket.state
  bucket   = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  for_each = aws_s3_bucket.state
  bucket   = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  for_each = aws_s3_bucket.state
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
