# Debug/audit log group - the rule's second target ships a copy of every
# matched event here, mirroring the CloudFormation template's
# `/aws/events/datadog-rule` log group target.
resource "aws_cloudwatch_log_group" "eventbridge_debug" {
  name              = "/aws/events/datadog-rule"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_event_rule" "recovery_rule" {
  name           = var.rule_name
  description    = "Forwards Datadog recovery alert notifications to the ${var.function_name} Lambda."
  event_bus_name = data.aws_cloudwatch_event_bus.datadog_recovery_bus.name
  state          = "ENABLED"

  event_pattern = jsonencode({
    source = [{
      prefix = var.event_source_prefix
    }]
    detail-type = var.event_pattern_detail_types
    detail = {
      alert_type = var.event_pattern_alert_types
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule           = aws_cloudwatch_event_rule.recovery_rule.name
  event_bus_name = data.aws_cloudwatch_event_bus.datadog_recovery_bus.name
  target_id      = "recovery-event-forwarder-lambda"

  arn      = aws_lambda_function.recovery_event_forwarder.arn
  role_arn = aws_iam_role.eventbridge_invoke_lambda.arn
}

resource "aws_cloudwatch_event_target" "debug_log" {
  rule           = aws_cloudwatch_event_rule.recovery_rule.name
  event_bus_name = data.aws_cloudwatch_event_bus.datadog_recovery_bus.name
  target_id      = "recovery-event-forwarder-debug-log"

  arn = aws_cloudwatch_log_group.eventbridge_debug.arn

  depends_on = [aws_cloudwatch_log_resource_policy.eventbridge_log_group]
}
