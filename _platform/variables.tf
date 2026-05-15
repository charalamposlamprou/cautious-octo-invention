variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "github_org" {
  type        = string
  description = "GitHub organisation or user that owns the repo."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name (without org)."
}

variable "service_name" {
  type        = string
  description = "Service name used as a prefix for IAM roles and in tags."
  default     = "app"
}
