# recovery-event-forwarder (Terraform)

Provisions:

- **Lambda function** (`RecoveryEventForwarder`) that reads a Datadog recovery
  alert event, pulls `aws_account` / `command` / `host` / `recovery` out of the
  event's tags, and re-publishes the event onto the destination account's
  default EventBridge bus.
- **Lambda execution role**, with `AWSLambdaBasicExecutionRole` for logs, plus
  an inline `events:PutEvents` policy scoped to each destination account's
  default bus (`var.destination_account_ids`).
- **EventBridge rule** on the existing Datadog partner event bus
  (looked up via `data.aws_cloudwatch_event_bus`, not created by Terraform),
  matching `aws.partner/datadog.com/*` sources, `Datadog Alert Notification`
  detail-type, and `alert_type` of `error`/`warning`.
- **EventBridge → Lambda invoke role**, a dedicated IAM role EventBridge
  assumes to invoke the Lambda target (trust policy scoped to this exact rule
  ARN), matching the CloudFormation reference template.
- A second rule **target that mirrors matched events to a CloudWatch log
  group** (`/aws/events/datadog-rule`) for debugging, with the resource policy
  EventBridge needs to write to it.

## Repo layout

```
.
├── README.md
├── versions.tf                  # Terraform + provider version pins, backend block (commented)
├── providers.tf                 # aws provider config
├── variables.tf                 # all input variables
├── data.tf                      # data sources: caller identity, partition, existing event bus, zip archive
├── iam.tf                       # Lambda execution role + EventBridge invoke role + policies
├── lambda.tf                    # aws_lambda_function + its log group
├── eventbridge.tf               # aws_cloudwatch_event_rule + targets + debug log group
├── outputs.tf
├── terraform.tfvars.example     # copy to terraform.tfvars and edit
├── .gitignore
├── src/
│   └── lambda_function.py       # Lambda handler source
└── .github/
    └── workflows/
        └── terraform.yml        # fmt/validate/plan/apply CI pipeline (OIDC)
```

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: region, function name, destination account IDs, etc.

terraform init
terraform plan
terraform apply
```

The Lambda deployment package is built automatically from `src/` via
`data.archive_file`, so there's no manual zipping step.

## Notes / things to double check before applying

1. **Existing event bus**: `data.aws_cloudwatch_event_bus` requires the
   Datadog partner event bus to already exist (i.e., the Datadog EventBridge
   integration has already been set up in this account/region) — Terraform
   will fail the plan if it can't find a bus with that exact name.
2. **Destination account IDs**: update `var.destination_account_ids` in
   `terraform.tfvars` to match the accounts you actually want to forward
   recovery events to; these map 1:1 to the `events:PutEvents` resource ARNs
   on the Lambda execution role.
3. **Remote state**: `versions.tf` has a commented-out `s3` backend block —
   uncomment and point it at your state bucket/DynamoDB lock table before
   using this in a team/CI setting.
4. **CI/CD**: `.github/workflows/terraform.yml` assumes an AWS IAM role via
   GitHub OIDC (`secrets.AWS_DEPLOY_ROLE_ARN`). Add that secret (or swap in
   your own auth method) and set up an environment protection rule on
   `production` if you want manual approval before `apply`.
