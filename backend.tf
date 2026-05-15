###############################################################################
# Partial backend config — bucket + region + key are supplied per-env via
# `-backend-config=backend/<env>.hcl` from the CI workflow.
###############################################################################

terraform {
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
