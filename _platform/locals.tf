locals {
  common_tags = {
    Service    = var.service_name
    ManagedBy  = "terraform"
    Owner      = "platform"
    CostCenter = "engineering"
    Stack      = "_platform"
  }
}
