variable "region" {
  description = "Primary AWS region."
  type        = string
  default     = "ap-southeast-2"
}

variable "alert_emails" {
  description = "Emails that receive budget alerts."
  type        = list(string)
  sensitive   = true

  validation {
    condition     = length(var.alert_emails) > 0
    error_message = "Provide at least one alert email."
  }
}

variable "monthly_limit_usd" {
  description = "Monthly cost budget in USD."
  type        = number
  default     = 5
}