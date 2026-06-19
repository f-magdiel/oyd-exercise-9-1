# **Exercise 9.1 \- Observability**

**Course:** Optimizaciones y Desempeño — Cloud Deployment Automation  
**Session:** 9 — June 18, 2026  
**Time allowed:** 30 minutes  
**Submission:** Initialize a new repository called oyd-exercise-9-1 and commit/push everything into it. Submit the repository URL only.

# Context

FinAPI is a fintech startup that processes payment requests behind an Application Load Balancer on AWS. The team has networking and compute already deployed via Terraform modules. With a production release scheduled for next week, the engineering lead has asked you to add a complete observability module: a CloudWatch log group, error-rate and latency alarms connected to an SNS email subscription, an EstimatedCharges alarm that fires near-real-time, and a monthly budget guard.

Your starter project has the following root files. Clone or copy them as your starting point.

### versions.tf

terraform {  
  required\_version \= "\>= 1.6"  
  required\_providers {  
    aws \= {  
      source  \= "hashicorp/aws"  
      version \= "\~\> 5.0"  
    }  
  }  
}

provider "aws" {  
  region \= var.aws\_region  
}

### variables.tf

variable "aws\_region" {  
  description \= "AWS region for all resources"  
  type        \= string  
  default     \= "us-east-2"  
}

variable "alb\_arn\_suffix" {  
  description \= "ARN suffix of your ALB (from the AWS console, e.g. app/my-alb/abc123def456)"  
  type        \= string  
}

variable "notification\_email" {  
  description \= "Email address that receives CloudWatch alarm notifications"  
  type        \= string  
}

variable "log\_retention\_days" {  
  description \= "Days to retain log group entries"  
  type        \= number  
  default     \= 14  
}

variable "monthly\_budget\_usd" {  
  description \= "Monthly budget ceiling in USD"  
  type        \= number  
  default     \= 25  
}

variable "estimated\_charges\_threshold" {  
  description \= "USD amount that triggers the EstimatedCharges alarm. Set to a value your account has already exceeded before class so the alarm fires and you can see it in the console."  
  type        \= number  
  default     \= 10  
}

### main.tf

\# Task 5: call the observability module here

### outputs.tf

\# Outputs to be added after the observability module is wired in

### envs/dev/dev.tfvars

aws\_region                  \= "us-east-2"  
alb\_arn\_suffix              \= "app/\<YOUR-ALB-NAME\>/\<YOUR-ALB-ID\>"  
notification\_email          \= "\<YOUR-EMAIL\>"  
log\_retention\_days          \= 14  
monthly\_budget\_usd          \= 25  
estimated\_charges\_threshold \= 10

# Setup

## Prerequisites

* AWS CLI configured with valid credentials (aws sts get-caller-identity should return your account ID)  
* Terraform \>= 1.6 installed  
* Your team's ALB ARN suffix — find it in the AWS console under EC2 \> Load Balancers; copy the value shown as "ARN suffix" on the detail page  
* An email address you can check during the exercise — AWS will send an SNS subscription confirmation you must click

## Repository structure

oyd-exercise-9-1/  
├── versions.tf  
├── main.tf  
├── variables.tf  
├── outputs.tf  
├── envs/  
│   └── dev/  
│       └── dev.tfvars  
└── modules/  
    └── observability/  
        ├── main.tf       ← create this  
        ├── variables.tf  ← create this  
        └── outputs.tf    ← create this

# Tasks

## Task 1 — Log group and SNS

Create modules/observability/main.tf. Add the following resources:

* aws\_cloudwatch\_log\_group — name /finapi/dev, retention controlled by a variable (default 14 days). Use name\_prefix if you want to avoid name conflicts.  
* aws\_sns\_topic — a single topic for alarm notifications (e.g. name \= "finapi-alerts").  
* aws\_sns\_topic\_subscription — protocol \= "email", endpoint \= the notification email variable, topic\_arn referencing the topic above.

Create modules/observability/variables.tf with input variables for: alb\_arn\_suffix, notification\_email, log\_retention\_days, monthly\_budget\_usd, estimated\_charges\_threshold, and aws\_region.

## Task 2 — HTTP 5xx and latency alarms

Still in modules/observability/main.tf, add two aws\_cloudwatch\_metric\_alarm resources:

1. HTTP 5xx error rate — namespace "AWS/ApplicationELB", metric\_name "HTTPCode\_Target\_5XX\_Count", dimension key "LoadBalancer" with value \= var.alb\_arn\_suffix. Set statistic \= "Sum", period \= 60, evaluation\_periods \= 2, threshold \= 5, comparison\_operator \= "GreaterThanOrEqualToThreshold", treat\_missing\_data \= "notBreaching".  
2. Target response time — same namespace and dimension, metric\_name "TargetResponseTime", statistic \= "Average", threshold \= 1 (seconds). Use treat\_missing\_data \= "notBreaching".

Both alarms must set alarm\_actions \= \[aws\_sns\_topic.alerts.arn\] and ok\_actions \= \[aws\_sns\_topic.alerts.arn\].

## Task 3 — EstimatedCharges alarm with us-east-1 alias

AWS billing metrics are only published in us-east-1. You need a provider alias to reach them regardless of your default region.

1. In root versions.tf, add a second provider "aws" block with alias \= "us\_east\_1" and region \= "us-east-1".  
2. In modules/observability/main.tf, add a terraform { } block declaring required\_providers with aws having configuration\_aliases \= \[aws.us\_east\_1\]. Then add a variable "providers" is not needed — the alias is passed via the providers map when calling the module.  
3. Add an aws\_cloudwatch\_metric\_alarm for EstimatedCharges: namespace \= "AWS/Billing", metric\_name \= "EstimatedCharges", dimensions \= { Currency \= "USD" }, statistic \= "Maximum", period \= 86400, evaluation\_periods \= 1, threshold \= var.estimated\_charges\_threshold, comparison\_operator \= "GreaterThanOrEqualToThreshold". Set provider \= aws.us\_east\_1 on this resource.  
4. Wire the alarm's alarm\_actions to the SNS topic ARN.

## Task 4 — Monthly budget guard

Add an aws\_budgets\_budget resource in modules/observability/main.tf:

* budget\_type \= "COST", time\_unit \= "MONTHLY"  
* limit\_amount \= var.monthly\_budget\_usd, limit\_unit \= "USD"  
* One cost\_notification block: threshold \= 80, threshold\_type \= "PERCENTAGE", notification\_type \= "ACTUAL", comparison\_operator \= "GREATER\_THAN", subscriber\_email\_addresses \= \[var.notification\_email\]

**Important:** aws\_budgets\_budget reads AWS billing data with a 24–48 hour lag. It is not suitable for real-time cost alerting. Use the EstimatedCharges alarm from Task 3 for near-real-time cost alerts; use this budget for a hard monthly ceiling.

## Task 5 — Wire the module from root

In root main.tf, call the observability module and pass the us-east-1 provider alias via a providers map:

module "observability" {  
  source \= "./modules/observability"

  alb\_arn\_suffix              \= var.alb\_arn\_suffix  
  notification\_email          \= var.notification\_email  
  log\_retention\_days          \= var.log\_retention\_days  
  monthly\_budget\_usd          \= var.monthly\_budget\_usd  
  estimated\_charges\_threshold \= var.estimated\_charges\_threshold  
  aws\_region                  \= var.aws\_region

  providers \= {  
    aws          \= aws  
    aws.us\_east\_1 \= aws.us\_east\_1  
  }  
}

Then run:

terraform init  
terraform apply \-var-file="envs/dev/dev.tfvars"

After apply, check your email and click the SNS subscription confirmation link AWS sends. The subscription status in the AWS console must show "Confirmed" before you submit.

# Acceptance Criteria

* modules/observability/main.tf declares aws\_cloudwatch\_log\_group, aws\_sns\_topic, aws\_sns\_topic\_subscription, aws\_cloudwatch\_metric\_alarm × 3 (HTTP 5xx, latency, EstimatedCharges), and aws\_budgets\_budget  
* The EstimatedCharges alarm resource sets provider \= aws.us\_east\_1  
* root versions.tf contains a provider "aws" block with alias \= "us\_east\_1" and region \= "us-east-1"  
* terraform apply completes without errors  
* Log group /finapi/dev (or similar) is visible in the CloudWatch console under Log groups — save a screenshot as evidence/log-group.png  
* At least one alarm is visible in the CloudWatch console in ALARM or OK state — save a screenshot as evidence/alarm.png  
* SNS subscription confirmation email was received and the link was clicked; subscription status in the AWS console shows Confirmed — save a screenshot as evidence/sns-confirmed.png  
* Repository is named oyd-exercise-9-1 and the URL is submitted

