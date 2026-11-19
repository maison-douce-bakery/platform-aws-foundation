# platform-aws-foundation

The base layer of the AWS platform. It creates what every other `platform-*` repo needs before it can run:

- **Terraform state storage**: an encrypted S3 bucket for remote state
- **Account guardrails**: budget, cost anomaly alerts, S3/EBS/EC2 security defaults, password policy
- **CI access**: plan and apply roles capped by a permission boundary
- **Audit**: a multi-region CloudTrail with immutable logs

## Why a separate repo

- **It must exist first.** Other repos store their state and get CI access through what this repo creates, so they cannot create it themselves.
- **Highest risk.** A mistake here can lock everyone out of AWS. Only admins apply changes.
- **Rarely changes.** It is changed every few months. App and infra repos change daily.

## Account model

A single AWS account (Free plan, `ap-southeast-2`). `dev`, `prod` and `shared` are separated by name and tags.

| Convention | Format |
|---|---|
| Resource name | `mdb-<env>-<name>` (e.g. `mdb-dev-dagu`) |
| Required tags | `Project=mdb`, `Environment=dev\|prod\|shared`, `ManagedBy=terraform`, `Repo=<repo>` |
| Platform IAM | Path `/platform/`. Workloads can't change anything under it |

## Layout

Each folder is a separate stack with its own state. For a fresh account, apply them in this order:

| Order | Stack | Creates |
|---|---|---|
| 1 | `bootstrap/` | State bucket and its KMS key |
| 2 | `account-baseline/` | Monthly budget, cost anomaly detection, S3/EBS/EC2 security defaults |
| 3 | `audit/` | CloudTrail, log bucket with Object Lock, log KMS key |
| 4 | `iam-baseline/` | Password policy, workload permission boundary |
| 5 | `ci-access/` | CI users and the `plan` / `apply` roles |

`bootstrap/` starts with local state, then moves its own state into the bucket it created.

## Making a change

`main` is protected. Every change goes through a pull request, and CI never applies this repo.

1. Create a branch.
2. In the stack folder, run `terraform plan`, then `terraform apply` with an admin session (`aws login`).
3. Open a PR. CI runs `fmt`, `validate`, `tflint` and a `plan` per stack. Every plan must show `No changes`, which proves the code matches AWS.
4. Merge with rebase.

**Prerequisites:** Terraform 1.17, AWS CLI, GitHub CLI.

**Secrets:** `account-baseline/` needs `alert_emails`. Copy `terraform.tfvars.example` to `terraform.tfvars` locally. CI reads it from the `ALERT_EMAILS` secret. Non-secret settings live in variable defaults, not in tfvars.

**Drift:** a scheduled plan runs every Monday and fails if live AWS no longer matches `main`.

## Using it from other repos

**State backend.** Use one key per stack, named `<repo>/<path>/terraform.tfstate`:

```hcl
terraform {
  backend "s3" {
    bucket       = "mdb-shared-tfstate-452258152479-ap-southeast-2-an"
    key          = "<repo>/<path>/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    kms_key_id   = "arn:aws:kms:ap-southeast-2:452258152479:key/ecb785de-52dc-491e-aedf-7933d87850c3"
    use_lockfile = true
  }
}
```

**CI credentials.** These GitHub org secrets and variables are granted per repo:

| Name | Kind | Use |
|---|---|---|
| `AWS_CI_PLAN_ACCESS_KEY_ID`, `AWS_CI_PLAN_SECRET_ACCESS_KEY` | Secret | Access key of `mdb-shared-ci-plan`. It can only assume the plan role |
| `AWS_CI_PLAN_ROLE_ARN` | Variable | Read-only role for `terraform plan` |
| `AWS_REGION` | Variable | `ap-southeast-2` |

The apply key is issued when the first repo needs `terraform apply` in CI. It goes into that repo's `production` environment, not into org secrets.

**IAM roles.** Every role created by CI must use the permission boundary `arn:aws:iam::452258152479:policy/platform/mdb-shared-workload-boundary`. Without it, `iam:CreateRole` is denied.

## Decisions

- **Single account.** Creating an AWS Organization upgrades a Free plan account to Paid, and it can't be undone.
- **S3 native locking.** `use_lockfile = true` (Terraform ≥ 1.10) instead of DynamoDB.
- **No GitHub OIDC.** The AWS-managed SCP on this account denies `iam:*Provider*` on both the Free and Paid plans ([AWS docs](https://docs.aws.amazon.com/accounts/latest/reference/scps-and-rcps-for-projects.html)). CI signs in as an IAM user that can only assume one role. The role does the work, uses short-lived credentials and is capped by the boundary. Moving to OIDC only means changing the role's trust policy.
- **Permission boundary instead of SCPs.** The account can't have its own SCPs. The boundary blocks privilege escalation and protects state, audit logs, keys, guardrails and budgets.
- **Access keys are created outside Terraform.** Otherwise the secret would be stored in state.
- **Not available in this account:** account alias, IAM Access Analyzer, SAML, IAM Roles Anywhere and IAM groups (blocked by SCP), Glacier storage classes (Free plan SCP), and cost allocation tags (linked accounts can't manage them).

## Runbook: rotate the CI plan key

Rotate at least every 90 days. A user can hold two keys, so CI keeps working during the swap.

1. Create a new key and write it into the org secrets with `aws iam create-access-key` piped into `gh secret set` (never print the secret).
2. Run the `terraform` workflow and check that the plans pass.
3. Deactivate the old key with `aws iam update-access-key --status Inactive`.
4. After a few days without errors, delete it with `aws iam delete-access-key`.
