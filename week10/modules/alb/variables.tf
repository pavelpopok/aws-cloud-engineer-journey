variable "project_name" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "VPC ID from networking module"
}

variable "public_subnet_1_id" {
  type        = string
  description = "Public subnet 1 from networking module"
}

variable "public_subnet_2_id" {
  type        = string
  description = "Public subnet 2 from networking module"
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB security group from networking module"
}

variable "container_port" {
  type = number
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate for HTTPS listener"
}

variable "domain_name" {
  type = string
}

variable "route53_zone_id" {
  type = string
}
