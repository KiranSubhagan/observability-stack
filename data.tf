# Current account/partition - used to build ARNs generically instead of hardcoding.
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

# The Datadog partner event bus already exists (created via the Datadog
# integration / EventBridge partner event source subscription), so we look
# it up rather than trying to manage it with Terraform.
data "aws_cloudwatch_event_bus" "datadog_recovery_bus" {
  name = var.event_bus_name
}

# Lambda deployment package, built from the src/ directory.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/lambda_function.zip"
}
