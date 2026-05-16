SHELL       := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.ONESHELL:
.DEFAULT_GOAL := help

PLATFORM_DIR := _platform

.PHONY: help check fmt platform-init platform-plan platform-apply platform-destroy gh-vars gh-envs gh-reviewers bootstrap

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*##"; printf "Targets:\n"} /^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

check: ## Verify required tools are installed and authenticated
	@for cmd in terraform aws gh jq; do
	  command -v $$cmd >/dev/null || { echo "missing: $$cmd"; exit 1; }
	done
	@echo "AWS:    $$(aws sts get-caller-identity --output text --query Arn)"
	@gh auth status >/dev/null && echo "GitHub: $$(gh api user -q .login)"

fmt: ## terraform fmt check (recursive)
	terraform fmt -check -recursive

# ── _platform stack ─────────────────────────────────────────────────────────
platform-init: ## terraform init for _platform
	terraform -chdir=$(PLATFORM_DIR) init -input=false

platform-plan: platform-init ## terraform plan for _platform
	terraform -chdir=$(PLATFORM_DIR) plan

platform-apply: platform-init ## terraform apply for _platform (OIDC + 4 IAM roles)
	terraform -chdir=$(PLATFORM_DIR) apply -auto-approve -input=false

platform-destroy: platform-init ## terraform destroy for _platform (DANGEROUS)
	terraform -chdir=$(PLATFORM_DIR) destroy

# ── GitHub repo wiring ──────────────────────────────────────────────────────
gh-vars: ## Push platform role ARNs into GitHub Actions repo variables
	OUTPUTS=$$(terraform -chdir=$(PLATFORM_DIR) output -json)
	gh variable set AWS_ROLE_DEV     -b "$$(echo "$$OUTPUTS" | jq -r .dev_infra_role_arn.value)"
	gh variable set AWS_ROLE_TEST    -b "$$(echo "$$OUTPUTS" | jq -r .test_infra_role_arn.value)"
	gh variable set AWS_ROLE_STAGING -b "$$(echo "$$OUTPUTS" | jq -r .staging_infra_role_arn.value)"
	gh variable set AWS_ROLE_PROD    -b "$$(echo "$$OUTPUTS" | jq -r .prod_infra_role_arn.value)"
	@echo "✓ GH variables set"

gh-envs: ## Create dev/test/staging/production environments + branch policies
	REPO=$$(gh repo view --json nameWithOwner -q .nameWithOwner)
	for ENV in dev test staging production; do
	  gh api --silent -X PUT "repos/$$REPO/environments/$$ENV"
	  echo "  ✓ env: $$ENV"
	done
	# Restrict staging + production to the master branch
	for ENV in staging production; do
	  gh api --silent -X PUT "repos/$$REPO/environments/$$ENV" \
	    -F "deployment_branch_policy[protected_branches]=false" \
	    -F "deployment_branch_policy[custom_branch_policies]=true"
	  existing=$$(gh api "repos/$$REPO/environments/$$ENV/deployment-branch-policies" \
	    --jq '.branch_policies[] | select(.name == "master") | .id' 2>/dev/null || true)
	  if [ -z "$$existing" ]; then
	    gh api --silent -X POST "repos/$$REPO/environments/$$ENV/deployment-branch-policies" -f "name=master"
	    echo "  ✓ $$ENV → branch policy added: master"
	  else
	    echo "  ✓ $$ENV → branch policy already set: master"
	  fi
	done

gh-reviewers: ## Set the current GitHub user as required reviewer on production
	REPO=$$(gh repo view --json nameWithOwner -q .nameWithOwner)
	USER_ID=$$(gh api user -q .id)
	gh api --silent -X PUT "repos/$$REPO/environments/production" \
	  -F "reviewers[][type]=User" \
	  -F "reviewers[][id]=$$USER_ID" \
	  -F "deployment_branch_policy[protected_branches]=false" \
	  -F "deployment_branch_policy[custom_branch_policies]=true"
	@echo "  ✓ production → required reviewer: $$(gh api user -q .login)"

# ── One-shot ────────────────────────────────────────────────────────────────
bootstrap: check platform-apply gh-vars gh-envs gh-reviewers ## Full bootstrap: apply + GH vars + environments + reviewers
	@echo ""
	@echo "✓ Bootstrap complete."
	@echo "Reminder: stash $(PLATFORM_DIR)/terraform.tfstate somewhere safe (1Password, private bucket)."
	@echo "Reviewer/approval rules for the GH Environments must be set manually in repo Settings."
