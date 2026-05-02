variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project_name" {
  type    = string
  default = "week10"
}

variable "aws_account_id" {
  type    = string
  default = "640768198958"
}

variable "container_port" {
  type    = number
  default = 5000
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS"
  default     = "arn:aws:acm:eu-central-1:640768198958:certificate/e597fe03-e907-47b4-90bc-34d3671a2fba"
}

variable "domain_name" {
  type        = string
  description = "Your registered domain"
  default     = "pavlopopok.click"
}

variable "route53_zone_id" {
  type        = string
  description = "Route 53 hosted zone ID"
  default     = "Z0082630D8JUXQ45ZEY5"
}
