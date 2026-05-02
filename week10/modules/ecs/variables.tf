variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "container_port" {
  type = number
}

variable "public_subnet_1_id" {
  type = string
}

variable "public_subnet_2_id" {
  type = string
}

variable "ecs_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type        = string
  description = "ALB target group ARN from alb module"
}

variable "desired_count" {
  type    = number
  default = 2
}
