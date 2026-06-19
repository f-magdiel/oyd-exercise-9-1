variable "aws_region" {
  description = "AWS region for the module resources"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  type        = string
}

variable "notification_email" {
  description = "Email address for alarm notifications"
  type        = string
}

variable "log_retention_days" {
  description = "Days to retain CloudWatch log group entries"
  type        = number
  default     = 14
}

variable "monthly_budget_usd" {
  description = "Monthly budget ceiling in USD"
  type        = number
  default     = 25
}

variable "estimated_charges_threshold" {
  description = "USD threshold that triggers the EstimatedCharges alarm"
  type        = number
  default     = 10
}
