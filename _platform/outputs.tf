output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider — referenced by per-env deploy roles via data source."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "dev_infra_role_arn" {
  description = "Set this as AWS_ROLE_DEV in repo Actions variables."
  value       = module.github_infra_role_dev.role_arn
}

output "test_infra_role_arn" {
  description = "Set this as AWS_ROLE_TEST in repo Actions variables."
  value       = module.github_infra_role_test.role_arn
}

output "staging_infra_role_arn" {
  description = "Set this as AWS_ROLE_STAGING in repo Actions variables."
  value       = module.github_infra_role_staging.role_arn
}

output "prod_infra_role_arn" {
  description = "Set this as AWS_ROLE_PROD in repo Actions variables."
  value       = module.github_infra_role_prod.role_arn
}

output "state_bucket_names" {
  description = "Per-env S3 buckets that hold Terraform state. Reference these in backend/<env>.hcl."
  value       = { for k, v in aws_s3_bucket.state : k => v.bucket }
}
