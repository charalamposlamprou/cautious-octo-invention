###############################################################################
# Root composition — applied once per environment (dev/test/staging/prod) via
# `terraform apply -var-file=envs/<env>.tfvars` with backend selected by
# `terraform init -backend-config=backend/<env>.hcl`.
#
# Add per-env resources (VPC, ECS, ECR, ALB, etc.) here or compose them
# from ./modules.
#
# (dummy-tfcmt: verify tfcmt plan + apply comments end-to-end on a fresh PR.)
###############################################################################
