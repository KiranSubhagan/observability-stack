resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_lambda_function" "recovery_event_forwarder" {
  function_name = var.function_name
  description   = "Forwards Datadog recovery alert events to the destination account's default EventBridge bus."

  role    = aws_iam_role.lambda_execution.arn
  handler = "lambda_function.lambda_handler"
  runtime = var.lambda_runtime

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.lambda_put_events,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.lambda,
  ]
}
