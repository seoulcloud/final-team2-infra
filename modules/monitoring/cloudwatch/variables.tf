variable "sns_topic_name" {
  description = "Name of the SNS topic for alerts"
  type        = string
}

variable "email_addresses" {
  description = "List of email addresses for SNS subscription"
  type        = list(string)
}

variable "alarm_name" {
  description = "CloudWatch alarm name"
  type        = string
}

variable "comparison_operator" {
  description = "Comparison operator for alarm"
  type        = string
}

variable "evaluation_periods" {
  description = "Number of periods for evaluation"
  type        = number
}

variable "metric_name" {
  description = "Name of the metric"
  type        = string
}

variable "namespace" {
  description = "Namespace of the metric (e.g., AWS/EC2, AWS/EKS)"
  type        = string
}

variable "period" {
  description = "Period in seconds over which the metric is applied"
  type        = number
}

variable "statistic" {
  description = "Statistic to apply to the alarm's associated metric"
  type        = string
}

variable "threshold" {
  description = "Threshold for the alarm"
  type        = number
}

variable "action_description" {
  description = "Suggested action when alarm is triggered"
  type        = string
}

variable "dimensions" {
  description = "Dimensions for the alarm"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
}