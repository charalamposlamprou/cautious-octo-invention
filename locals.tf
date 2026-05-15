locals {
  name_prefix = "${var.service_name}-${var.environment}"

  common_tags = {
    Service     = var.service_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
