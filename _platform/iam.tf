###############################################################################
# Broad infra-apply permissions, used by terraform.yml plan/apply jobs.
# Keep this policy here (in _platform) rather than per-env so the role used
# by `terraform destroy` is not part of the env state being destroyed.
###############################################################################

data "aws_iam_policy_document" "infra_apply" {
  statement {
    sid       = "Network"
    effect    = "Allow"
    actions   = ["ec2:*"]
    resources = ["*"]
  }
  statement {
    sid       = "IAM"
    effect    = "Allow"
    actions   = ["iam:*"]
    resources = ["*"]
  }
  statement {
    sid       = "ECS"
    effect    = "Allow"
    actions   = ["ecs:*", "application-autoscaling:*"]
    resources = ["*"]
  }
  statement {
    sid       = "ECR"
    effect    = "Allow"
    actions   = ["ecr:*"]
    resources = ["*"]
  }
  statement {
    sid       = "S3"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
  statement {
    sid       = "CloudFront"
    effect    = "Allow"
    actions   = ["cloudfront:*"]
    resources = ["*"]
  }
  statement {
    sid       = "WAF"
    effect    = "Allow"
    actions   = ["wafv2:*"]
    resources = ["*"]
  }
  statement {
    sid       = "ELB"
    effect    = "Allow"
    actions   = ["elasticloadbalancing:*"]
    resources = ["*"]
  }
  statement {
    sid       = "CloudWatch"
    effect    = "Allow"
    actions   = ["logs:*", "cloudwatch:*"]
    resources = ["*"]
  }
  statement {
    sid       = "SSM"
    effect    = "Allow"
    actions   = ["ssm:*", "kms:DescribeKey"]
    resources = ["*"]
  }
  statement {
    sid       = "STS"
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity", "sts:GetServiceBearerToken"]
    resources = ["*"]
  }
}
