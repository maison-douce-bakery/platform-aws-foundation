# platform-aws-foundation

The base layer of the AWS platform. It creates what every other `platform-*` repo needs before it can run:

- **Terraform state storage**: an S3 bucket for remote state
- **IAM baseline**: account settings and permission boundaries
- **CI access**: GitHub OIDC roles, so no AWS keys are stored in GitHub
- **Audit and cost**: CloudTrail and budgets

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

The `Environment` tag is also a security boundary. IAM policies use it to stop dev roles from touching prod resources.

## Layout

Each folder has its own state, applied in this order:

1. `bootstrap/`: S3 state bucket
2. `iam-baseline/`: alias, password policy, Access Analyzer, permission boundary
3. `github-oidc/`: OIDC provider, `plan` and `apply` roles
4. `audit/`: CloudTrail, budgets

## Decisions

- **Single account.** Creating an AWS Organization upgrades a Free plan account to Paid, and it can't be undone. An `organization/` folder will be added when the account moves to Paid.
- **S3 native locking.** Use `use_lockfile = true` (Terraform ≥ 1.10) instead of DynamoDB.
