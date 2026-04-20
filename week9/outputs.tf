output "vpc_id" { value = aws_vpc.main.id }
output "public_subnet_1_id" { value = aws_subnet.public_1.id }
output "public_subnet_2_id" { value = aws_subnet.public_2.id }
output "ecs_cluster_name" { value = aws_ecs_cluster.main.name }
output "ecs_sg_id" { value = aws_security_group.ecs.id }
output "alb_sg_id" { value = aws_security_group.alb.id }
output "task_definition_arn" { value = aws_ecs_task_definition.app.arn }
output "alb_dns_name" {
  description = "Open this in your browser"
  value       = aws_lb.main.dns_name
}
output "dashboard_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}-dashboard"
}
output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "domain_url" {
  description = "App running on HTTPS with real domain"
  value       = "https://${var.domain_name}"
}
