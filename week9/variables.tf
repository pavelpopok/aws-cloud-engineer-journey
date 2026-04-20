variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project_name" {
  type    = string
  default = "week5"
}

variable "aws_account_id" {
  type    = string
  default = "640768198958"
}

variable "container_port" {
  type    = number
  default = 5000
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "pavel.popok@gmail.com"
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS listener"
  type        = string
  default     = "arn:aws:acm:eu-central-1:640768198958:certificate/e597fe03-e907-47b4-90bc-34d3671a2fba"
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for pavlopopok.click"
  type        = string
  default     = "Z0082630D8JUXQ45ZEY5"
}

variable "domain_name" {
  description = "Registered domain name"
  type        = string
  default     = "pavlopopok.click"
}
