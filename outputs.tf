output "lambda_function_name" {
  description = "Name of the deployed Lambda function."
  value       = aws_lambda_function.recovery_event_forwarder.function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function."
  value       = aws_lambda_function.recovery_event_forwarder.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda's execution role."
  value       = aws_iam_role.lambda_execution.arn
}

output "eventbridge_invoke_role_arn" {
  description = "ARN of the role EventBridge assumes to invoke the Lambda target."
  value       = aws_iam_role.eventbridge_invoke_lambda.arn
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule."
  value       = aws_cloudwatch_event_rule.recovery_rule.arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule."
  value       = aws_cloudwatch_event_rule.recovery_rule.name
}

output "event_bus_name" {
  description = "Name of the Datadog partner event bus the rule is attached to."
  value       = data.aws_cloudwatch_event_bus.datadog_recovery_bus.name
}
