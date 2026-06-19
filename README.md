# Exercise 9.1 — Observability on AWS

**Course:** Optimizaciones y Desempeño — Cloud Deployment Automation  
**Session:** 9 — June 18, 2026  
**Student:** Magdiel Asicona  
**Repository:** oyd-exercise-9-1

---

## Objective

Add a complete observability module to a simulated FinAPI infrastructure on AWS, including:

- CloudWatch log group
- SNS topic with email subscription for alarm notifications
- CloudWatch alarms for HTTP 5xx errors and target response latency
- EstimatedCharges billing alarm (us-east-1)
- Monthly budget guard via AWS Budgets

---

## Repository Structure

```
oyd-exercise-9-1/
├── versions.tf                  # Terraform & provider configuration (default + us-east-1 alias)
├── variables.tf                 # Root input variables
├── main.tf                      # Calls the observability module (Task 5)
├── outputs.tf                   # Exposes module outputs
├── envs/
│   └── dev/
│       └── dev.tfvars           # Dev environment variable values
├── modules/
│   └── observability/
│       ├── main.tf              # All resources: Tasks 1–4
│       ├── variables.tf         # Module input variables
│       └── outputs.tf           # Module outputs
└── evidence/
    ├── log-group.png
    ├── alarm.png
    └── sns-confirmed.png
```

---

## Tasks Completed

### Task 1 — Log Group and SNS

- `aws_cloudwatch_log_group` → `/finapi/dev`, retention 14 days
- `aws_sns_topic` → `finapi-alerts` (us-east-2)
- `aws_sns_topic_subscription` → email to notification address

### Task 2 — HTTP 5xx and Latency Alarms

- `aws_cloudwatch_metric_alarm` → `finapi-http-5xx-errors`
  - Namespace: `AWS/ApplicationELB` | Metric: `HTTPCode_Target_5XX_Count`
  - Statistic: Sum | Period: 60s | Evaluation periods: 2 | Threshold: ≥ 5
- `aws_cloudwatch_metric_alarm` → `finapi-target-response-time`
  - Namespace: `AWS/ApplicationELB` | Metric: `TargetResponseTime`
  - Statistic: Average | Threshold: ≥ 1 second
- Both alarms use `treat_missing_data = "notBreaching"` and notify via SNS

### Task 3 — EstimatedCharges Alarm (us-east-1)

- AWS billing metrics are only published in `us-east-1` — a provider alias was declared in `versions.tf`
- A dedicated SNS topic `finapi-alerts-billing` was created in `us-east-1` (cross-region SNS actions are not supported)
- `aws_cloudwatch_metric_alarm` → `finapi-estimated-charges`
  - Namespace: `AWS/Billing` | Metric: `EstimatedCharges` | Currency: USD
  - Threshold: ≥ $10 | Period: 86400s | `provider = aws.us_east_1`

### Task 4 — Monthly Budget Guard

- `aws_budgets_budget` → `finapi-monthly-budget`
  - Type: COST | Period: MONTHLY | Limit: $25 USD
  - Notification at 80% of actual spend via email

### Task 5 — Module Wiring

- Root `main.tf` calls `./modules/observability` and passes both providers via `providers` map:

```hcl
providers = {
  aws           = aws
  aws.us_east_1 = aws.us_east_1
}
```

---

## Terraform Apply Output

```
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

alarm_5xx_name               = "finapi-http-5xx-errors"
alarm_estimated_charges_name = "finapi-estimated-charges"
alarm_latency_name           = "finapi-target-response-time"
log_group_name               = "/finapi/dev"
sns_topic_arn                = "arn:aws:sns:us-east-2:230195036018:finapi-alerts"
```

---

## Evidence

### Log Group `/finapi/dev` — CloudWatch

![CloudWatch Log Group /finapi/dev](evidence/Screenshot%202026-06-18%20at%2020-01-11.png)

---

### CloudWatch Alarms

![CloudWatch Alarms](evidence/Screenshot%202026-06-18%20at%2020-02-14.png)

---

### SNS Subscription Confirmed

![SNS Subscription Confirmed](evidence/Screenshot%202026-06-18%20at%2020-03-50.png)

---
