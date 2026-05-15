variable "create_oidc_provider" {
  type        = bool
  description = "Create the GitHub Actions OIDC provider in this AWS account. The provider is account-wide; only ONE composition should set this true."
  default     = false
}

variable "github_org" {
  type        = string
  description = "GitHub organisation or user that owns the repo."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name (without org)."
}

variable "subject_filters" {
  type        = list(string)
  description = "List of GitHub OIDC `sub` claim suffixes allowed to assume the role. Each is prefixed with `repo:<org>/<repo>:`. Examples: \"environment:prod\", \"ref:refs/heads/main\", \"pull_request\"."
}

variable "role_name" {
  type        = string
  description = "Name of the IAM role to create."
}

variable "role_policy_json" {
  type        = string
  description = "Inline IAM policy JSON granting the role its permissions. Use aws_iam_policy_document data source in the caller."
}

variable "max_session_duration" {
  type        = number
  description = "Maximum session duration in seconds. AWS minimum 3600, maximum 43200."
  default     = 3600
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to the role."
}
