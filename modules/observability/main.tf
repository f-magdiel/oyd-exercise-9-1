# Declare the provider alias that the root module must pass in
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# ---------------------------------------------------------------------------
# Task 1 — Log group and SNS
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "finapi" {
  name              = "/finapi/dev"
  retention_in_days = var.log_retention_days
}

resource "aws_sns_topic" "alerts" {
  name = "finapi-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# ---------------------------------------------------------------------------
# Task 2 — HTTP 5xx error-rate alarm and latency alarm
# Note: alb_arn_suffix is treated as a variable input (no real ALB required).
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  alarm_name          = "finapi-http-5xx-errors"
  alarm_description   = "Fires when ALB target 5xx count >= 5 in 2 consecutive 1-min periods"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name          = "finapi-target-response-time"
  alarm_description   = "Fires when average target response time >= 1 second"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ---------------------------------------------------------------------------
# Task 3 — EstimatedCharges alarm (must use us-east-1 provider alias)
# Billing metrics only exist in us-east-1; the SNS topic for alarm_actions
# must also be in us-east-1 (same region as the alarm).
# ---------------------------------------------------------------------------

# SNS topic in us-east-1 for billing alarm notifications
resource "aws_sns_topic" "alerts_billing" {
  provider = aws.us_east_1
  name     = "finapi-alerts-billing"
}

resource "aws_sns_topic_subscription" "email_billing" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.alerts_billing.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_cloudwatch_metric_alarm" "estimated_charges" {
  provider = aws.us_east_1

  alarm_name          = "finapi-estimated-charges"
  alarm_description   = "Fires when estimated AWS charges reach the configured threshold"
  namespace           = "AWS/Billing"
  metric_name         = "EstimatedCharges"
  statistic           = "Maximum"
  period              = 86400
  evaluation_periods  = 1
  threshold           = var.estimated_charges_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    Currency = "USD"
  }

  alarm_actions = [aws_sns_topic.alerts_billing.arn]
}

# ---------------------------------------------------------------------------
# Task 4 — Monthly budget guard
# ---------------------------------------------------------------------------

resource "aws_budgets_budget" "monthly" {
  name         = "finapi-monthly-budget"
  budget_type  = "COST"
  time_unit    = "MONTHLY"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"

  notification {
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    comparison_operator        = "GREATER_THAN"
    subscriber_email_addresses = [var.notification_email]
  }
}
