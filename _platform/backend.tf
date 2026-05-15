terraform {
  backend "s3" {
    key          = "_platform/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
