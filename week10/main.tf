module "networking" {
  source = "./modules/networking"

  project_name   = var.project_name
  aws_region     = var.aws_region
  container_port = var.container_port
}

module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  vpc_id                = module.networking.vpc_id
  public_subnet_1_id    = module.networking.public_subnet_1_id
  public_subnet_2_id    = module.networking.public_subnet_2_id
  alb_security_group_id = module.networking.alb_security_group_id
  container_port        = var.container_port
  acm_certificate_arn   = var.acm_certificate_arn
  domain_name           = var.domain_name
  route53_zone_id       = var.route53_zone_id
}

module "ecs" {
  source = "./modules/ecs"

  project_name          = var.project_name
  aws_region            = var.aws_region
  aws_account_id        = var.aws_account_id
  container_port        = var.container_port
  public_subnet_1_id    = module.networking.public_subnet_1_id
  public_subnet_2_id    = module.networking.public_subnet_2_id
  ecs_security_group_id = module.networking.ecs_security_group_id
  target_group_arn      = module.alb.target_group_arn
  desired_count         = 0
}
