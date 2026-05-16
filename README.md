# cautious-octo-invention

Multi-environment Terraform setup driven by GitHub Actions, with OIDC-based AWS
auth, per-env state isolation, reviewer-gated applies, and a separate
manually-triggered destroy workflow.

## Repository layout

```
.
├── *.tf                       # Root composition — one terraform module
│                              # applied per env via -var-file + -backend-config
├── envs/{dev,test,staging,prod}.tfvars   # Per-env input variables
├── backend/{dev,test,staging,prod}.hcl   # Per-env S3 backend (bucket + key)
│
├── _platform/                 # Bootstrap-once stack (local state)
│   └── *.tf                   #   OIDC provider, 4 IAM roles, 4 state buckets
│
├── modules/iam-oidc/          # Reusable OIDC role module used by _platform
│
├── Makefile                   # Bootstrap automation (see below)
│
└── .github/
    ├── workflows/
    │   ├── terraform-pr.yml       # PR event → plan + apply dev/test
    │   ├── terraform-main.yml     # main push → plan + apply staging/prod
    │   └── terraform-destroy.yml  # workflow_dispatch → destroy any env(s)
    └── actions/
        ├── tf-plan/               # Composite: init + validate + plan + tfcmt
        └── tf-apply/              # Composite: init + download plan + apply
```

## Prerequisites

- AWS account with admin credentials available locally (`aws sts get-caller-identity` should work)
- `terraform >= 1.10` (uses native S3 lockfile)
- `gh` CLI authenticated
- `jq`
- GNU Make (3.81 from stock macOS is fine)

## Bootstrap

The `_platform` stack creates everything needed before the per-env workflows
can run: the GitHub OIDC provider, four IAM roles, and four S3 state buckets.
It runs once from your laptop and uses **local state** (gitignored, so don't
lose it).

```bash
make bootstrap
```

This chains:

| Step | What it does |
|---|---|
| `check` | Verifies terraform / aws / gh / jq are installed and authenticated |
| `platform-apply` | `terraform apply` in `_platform/` — creates OIDC + 4 IAM roles + 4 state buckets |
| `gh-vars` | Pushes the role ARNs into repo Actions variables (`AWS_ROLE_{DEV,TEST,STAGING,PROD}`) |
| `gh-envs` | Creates the four GitHub Environments (`dev`, `test`, `staging`, `production`) and restricts staging + production to the `main` branch |
| `gh-reviewers` | Adds the current `gh auth` user as required reviewer on every env |

The Makefile is idempotent — re-running is safe.

After bootstrap, stash `_platform/terraform.tfstate` somewhere durable
(1Password attachment, private bucket). You only need it to rotate trust
policies later.

## Workflows

### Terraform (PR) — `terraform-pr.yml`

Fires on `pull_request` events for any base branch.

```
Lint & Scan
  ├─ Plan - dev   ── Apply - dev   (env: dev,  reviewer-gated)
  └─ Plan - test  ── Apply - test  (env: test, reviewer-gated)
```

Each apply pauses for your "Review pending deployments" click. tfcmt posts
plan + apply comments on the PR.

### Terraform (main) — `terraform-main.yml`

Fires on `push` to `main` (typically after a PR merge).

```
Lint & Scan
  ├─ Plan - staging ── Apply - staging ─┐
  └─ Plan - prod  ─────────────────────  └── Apply - prod
```

Plans run in parallel; apply-prod waits for both its own plan AND
apply-staging completing — so you always verify staging before prod.

### Terraform (destroy) — `terraform-destroy.yml`

Manually triggered via `workflow_dispatch`. You must type `destroy` into the
confirmation input or the run aborts.

```
guard (confirmation check)
  ├─ Plan destroy - dev      ── Apply destroy - dev
  ├─ Plan destroy - test     ── Apply destroy - test
  ├─ Plan destroy - staging  ── Apply destroy - staging
  └─ Plan destroy - prod     ── Apply destroy - prod
```

Each apply-destroy is reviewer-gated. Approve only the envs you actually want
to wipe; skipping approval leaves that env intact.

Run from the `main` branch — staging/prod OIDC trust requires it.

## Day-to-day flow

1. Open a PR with infra changes.
2. CI runs lint + plan-dev + plan-test. tfcmt posts a comment per env with the
   diff.
3. Approve apply-dev → resources land in dev. Same for apply-test.
4. Merge PR.
5. The merge-commit push to `main` fires the staging/prod pipeline.
6. Approve apply-staging → staging deploys → apply-prod becomes available →
   approve → prod deploys.

## Authentication model

All AWS access is via GitHub OIDC. No long-lived access keys anywhere.

| Role | Trust subjects |
|---|---|
| `app-dev-github-infra` | `environment:dev`, `ref:refs/heads/*`, `pull_request` |
| `app-test-github-infra` | `environment:test`, `ref:refs/heads/*`, `pull_request` |
| `app-staging-github-infra` | `environment:staging`, `ref:refs/heads/main` |
| `app-prod-github-infra` | `environment:production`, `ref:refs/heads/main` |

Each role has broad service-level permissions (intended for an infra-apply
role); narrow these as the project takes shape.

## State

- Each env's state lives in its own S3 bucket: `app-tfstate-<env>-<account_id>`.
- Versioning + AES256 SSE + full public-access block on every bucket.
- Locking via Terraform 1.10's native S3 lockfile (`use_lockfile = true` in
  `backend.tf`). No DynamoDB table required.
- `_platform` state is **local** to the laptop that bootstrapped it.

---

## Roadmap / improvements to add

These are deliberate gaps in the current setup. Pick from the top as the
project's needs grow.

### High value

- **Drift detection.** Scheduled workflow (e.g., nightly cron) that runs
  `terraform plan` against each env and opens an issue / Slack message if the
  plan is non-empty. Catches manual console changes and out-of-band edits.
- **Cost estimation.** Wire [infracost](https://github.com/infracost/infracost)
  into the plan job so the PR comment also shows monthly $ impact per env.
- **Move `_platform` state to S3.** Create a fifth bucket
  `app-tfstate-platform-<account_id>`, then `terraform init -migrate-state`
  inside `_platform`. Removes the "lose laptop = lose platform state" risk.
- **Backend HCL parameterization.** The bucket names in `backend/*.hcl`
  currently hardcode account ID `970601848194`. Generate them from a Make
  target (`make backend-config`) reading the live `aws sts get-caller-identity`
  so forks/other accounts work without manual edits.

### Medium value

- **Stronger security scanning.** tfsec is OK but losing maintenance momentum.
  Add [Checkov](https://github.com/bridgecrewio/checkov) or
  [Trivy config](https://github.com/aquasecurity/trivy) for broader coverage.
- **Tag policy enforcement.** Fail the plan job if a resource lacks the
  service / env / owner tags (e.g., via a Checkov custom policy or `terraform-compliance`).
- **Two-person approval for production.** Currently only one reviewer. Add a
  teammate or require a separate "production-approver" group.
- **PR title / branch convention check.** Reject PRs whose title doesn't
  match a convention (e.g., `feat:`, `fix:`).
- **Plan artifact retention.** Currently 1 day. Bump to 30+ days (or push to
  S3) for compliance / postmortem audit trails.

### Nice to have

- **Integration tests.** [terratest](https://github.com/gruntwork-io/terratest)
  or [kitchen-terraform](https://github.com/newcontext-oss/kitchen-terraform)
  to assert real behavior of the applied infrastructure (not just `plan`
  succeeds).
- **Per-env destroy dispatch.** Make `terraform-destroy.yml` accept an
  `environment` input so you only plan-destroy the one env, instead of always
  fanning out to all four.
- **OPA / Sentinel policies.** Programmatic policy-as-code checks
  (e.g., "no public S3 buckets", "no IAM `*` actions", "tag drift") beyond
  what tfsec catches.
- **Slack / Discord notifications.** Notify a channel when apply-prod is
  pending review or when drift detection triggers.

### Won't do (yet)

- **Per-env AWS accounts.** Real isolation. But adds significant complexity
  (cross-account state, multi-account OIDC provider per account); revisit
  once the workload justifies it.
- **GitOps / Atlantis / Spacelift.** External CD tools that replace this
  workflow. Stay with GitHub Actions until that becomes a bottleneck.
