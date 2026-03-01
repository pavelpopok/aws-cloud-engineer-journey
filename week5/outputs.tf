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
