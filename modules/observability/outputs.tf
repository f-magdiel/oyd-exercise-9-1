output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.finapi.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "alarm_5xx_name" {
  description = "Name of the HTTP 5xx error-rate alarm"
  value       = aws_cloudwatch_metric_alarm.http_5xx.alarm_name
}

output "alarm_latency_name" {
  description = "Name of the latency alarm"
  value       = aws_cloudwatch_metric_alarm.latency.alarm_name
}

output "alarm_estimated_charges_name" {
  description = "Name of the EstimatedCharges alarm"
  value       = aws_cloudwatch_metric_alarm.estimated_charges.alarm_name
}
