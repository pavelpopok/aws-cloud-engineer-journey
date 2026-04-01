output "rds_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "RDS connection endpoint"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "Open this URL in your browser to see the Flask response"
}
