###############################################################################
# Root composition — applied once per environment (dev/test/staging/prod) via
# `terraform apply -var-file=envs/<env>.tfvars` with backend selected by
# `terraform init -backend-config=backend/<env>.hcl`.
#
# Add per-env resources (VPC, ECS, ECR, ALB, etc.) here or compose them
# from ./modules.
#
# (dummy-pr-2: verifying the split workflow only shows the PR path graph.)
# (extra line to test that a follow-up push triggers one new PR-event run.)
# (third dummy commit.)
###############################################################################
