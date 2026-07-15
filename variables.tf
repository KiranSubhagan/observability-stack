variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
  default     = "RecoveryEventForwarder"
}

variable "lambda_runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB."
  type        = number
  default     = 128
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days for the Lambda log group and the EventBridge debug log group."
  type        = number
  default     = 30
}

# --- EventBridge partner event bus (Datadog) ---

variable "event_bus_name" {
  description = "Name of the existing Datadog partner event bus that the rule is attached to."
  type        = string
  default     = "aws.partner/datadog.com/recovery-bus-yzp9s74x"
}

variable "rule_name" {
  description = "Name of the EventBridge rule."
  type        = string
  default     = "recovery-rule-forward-to-lambda"
}

variable "event_pattern_detail_types" {
  description = "detail-type values to match in the EventBridge rule."
  type        = list(string)
  default     = ["Datadog Alert Notification"]
}

variable "event_pattern_alert_types" {
  description = "alert_type values (in event detail) to match in the EventBridge rule."
  type        = list(string)
  default     = ["error", "warning"]
}

variable "event_source_prefix" {
  description = "Source prefix to match in the EventBridge rule."
  type        = string
  default     = "aws.partner/datadog.com/"
}

# --- Downstream event buses the Lambda is allowed to forward events to ---

variable "destination_account_ids" {
  description = "AWS account IDs whose default event bus the Lambda's execution role is allowed to call events:PutEvents on."
  type        = list(string)
  default = [
    "945203152184",
    "106948908544",
  ]
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "recovery-event-forwarder"
    ManagedBy = "terraform"
  }
}
