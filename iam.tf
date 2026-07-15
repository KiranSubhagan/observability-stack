########################################
# Lambda execution role
########################################

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_execution" {
  name               = "${var.function_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

# Basic CloudWatch Logs permissions for the function itself.
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# events:PutEvents on each destination account's default event bus,
# mirroring the policy supplied:
#
# {
#   "Version": "2012-10-17",
#   "Statement": [{
#     "Sid": "VisualEditor0",
#     "Effect": "Allow",
#     "Action": "events:PutEvents",
#     "Resource": [
#       "arn:aws:events:us-east-1:945203152184:event-bus/default",
#       "arn:aws:events:us-east-1:106948908544:event-bus/default"
#     ]
#   }]
# }
data "aws_iam_policy_document" "lambda_put_events" {
  statement {
    sid       = "VisualEditor0"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [
      for acct in var.destination_account_ids :
      "arn:${data.aws_partition.current.partition}:events:${var.aws_region}:${acct}:event-bus/default"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_put_events" {
  name   = "${var.function_name}-put-events"
  role   = aws_iam_role.lambda_execution.id
  policy = data.aws_iam_policy_document.lambda_put_events.json
}

########################################
# Role assumed by EventBridge to invoke the Lambda target
#
# This mirrors the CloudFormation template, which creates a dedicated
# execution role (with a trust policy scoped to the specific rule ARN)
# rather than relying solely on a Lambda resource-based (aws_lambda_permission)
# grant.
########################################

data "aws_iam_policy_document" "eventbridge_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        "arn:${data.aws_partition.current.partition}:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/${var.event_bus_name}/${var.rule_name}"
      ]
    }
  }
}

resource "aws_iam_role" "eventbridge_invoke_lambda" {
  name                 = "Amazon_EventBridge_Rule_Target_${var.rule_name}"
  assume_role_policy   = data.aws_iam_policy_document.eventbridge_assume_role.json
  max_session_duration = 3600
  tags                 = var.tags
}

data "aws_iam_policy_document" "eventbridge_invoke_lambda" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.recovery_event_forwarder.arn]
  }
}

resource "aws_iam_role_policy" "eventbridge_invoke_lambda" {
  name   = "Amazon_EventBridge_Invoke_Lambda_${var.function_name}"
  role   = aws_iam_role.eventbridge_invoke_lambda.id
  policy = data.aws_iam_policy_document.eventbridge_invoke_lambda.json
}

########################################
# Resource policy allowing EventBridge to write to the debug log group target
########################################

data "aws_iam_policy_document" "eventbridge_log_group" {
  statement {
    effect  = "Allow"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]

    resources = [
      "${aws_cloudwatch_log_group.eventbridge_debug.arn}:*",
    ]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "eventbridge_log_group" {
  policy_name     = "${var.rule_name}-log-policy"
  policy_document = data.aws_iam_policy_document.eventbridge_log_group.json
}
