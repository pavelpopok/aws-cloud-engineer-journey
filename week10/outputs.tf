output "https_url" {
  value       = module.alb.https_url
  description = "Your app URL"
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "availability_zones" {
  value = module.networking.availability_zones_used
}
