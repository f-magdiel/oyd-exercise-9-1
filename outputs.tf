output "log_group_name" {
  description = "CloudWatch log group name"
  value       = module.observability.log_group_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = module.observability.sns_topic_arn
}

output "alarm_5xx_name" {
  description = "Name of the HTTP 5xx CloudWatch alarm"
  value       = module.observability.alarm_5xx_name
}

output "alarm_latency_name" {
  description = "Name of the latency CloudWatch alarm"
  value       = module.observability.alarm_latency_name
}

output "alarm_estimated_charges_name" {
  description = "Name of the EstimatedCharges CloudWatch alarm"
  value       = module.observability.alarm_estimated_charges_name
}
