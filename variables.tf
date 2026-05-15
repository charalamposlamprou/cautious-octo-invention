variable "environment" {
  type        = string
  description = "Logical environment name: dev, test, staging, or prod."

  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, staging, prod."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for this environment."
  default     = "eu-west-1"
}

variable "service_name" {
  type        = string
  description = "Service name used as a prefix for resource names and in tags."
  default     = "app"
}
