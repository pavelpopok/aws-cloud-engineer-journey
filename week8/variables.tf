variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project_name" {
  type    = string
  default = "week8"
}

variable "aws_account_id" {
  type    = string
  default = "640768198958"
}

variable "container_port" {
  type    = number
  default = 5000
}

variable "db_username" {
  type        = string
  description = "RDS master username"
  default     = "week8admin"
}

variable "alert_email" {
  type    = string
  default = ""
}
