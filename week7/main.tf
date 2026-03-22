resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.project_name}-vpc", Project = var.project_name, CanDelete = "yes" }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public-1", Project = var.project_name, CanDelete = "yes" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public-2", Project = var.project_name, CanDelete = "yes" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw", Project = var.project_name, CanDelete = "yes" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project_name}-public-rt", Project = var.project_name, CanDelete = "yes" }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# ── SECURITY GROUPS ───────────────────────────────────

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB inbound HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg", Project = var.project_name, CanDelete = "yes" }
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "ECS tasks - only from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ecs-sg", Project = var.project_name, CanDelete = "yes" }
}

# ── ECS CLUSTER ───────────────────────────────────────

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  tags = { Name = "${var.project_name}-cluster", Project = var.project_name, CanDelete = "yes" }
}

# ── IAM EXECUTION ROLE ────────────────────────────────

resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = { Project = var.project_name, CanDelete = "yes" }
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ── CLOUDWATCH LOGS ───────────────────────────────────

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
  tags              = { Project = var.project_name, CanDelete = "yes" }
}

# ── TASK DEFINITION ───────────────────────────────────

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name  = "${var.project_name}-container"
    image = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/week6-flask:latest"

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project_name}"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    essential = true
  }])

  tags = { Project = var.project_name, CanDelete = "yes" }
}

# ── APPLICATION LOAD BALANCER ─────────────────────────

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  tags               = { Name = "${var.project_name}-alb", Project = var.project_name, CanDelete = "yes" }
}

# ── TARGET GROUP ──────────────────────────────────────

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/health"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = { Project = var.project_name, CanDelete = "yes" }
}

# ── LISTENER ──────────────────────────────────────────

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ── ECS SERVICE ───────────────────────────────────────

resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.project_name}-container"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]

  tags = { Project = var.project_name, CanDelete = "yes" }
}

# ─────────────────────────────────────────
# MONITORING — SNS
# ─────────────────────────────────────────

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
  tags = { Project = var.project_name, CanDelete = "yes" }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ─────────────────────────────────────────
# MONITORING — ALARMS
# ─────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.project_name}-unhealthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = 2
  alarm_description   = "ECS healthy task count dropped below 2"
  treat_missing_data  = "breaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = { Project = var.project_name, CanDelete = "yes" }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS CPU above 80% for 10 minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = { Project = var.project_name, CanDelete = "yes" }
}

# ─────────────────────────────────────────
# MONITORING — DASHBOARD
# ─────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "Healthy Host Count"
          region = var.aws_region
          period = 60
          stat   = "Minimum"
          metrics = [["AWS/ApplicationELB", "HealthyHostCount",
            "LoadBalancer", aws_lb.main.arn_suffix,
          "TargetGroup", aws_lb_target_group.app.arn_suffix]]
        }
      },
      {
        type = "metric"
        properties = {
          title  = "ECS CPU Utilization"
          region = var.aws_region
          period = 300
          stat   = "Average"
          metrics = [["AWS/ECS", "CPUUtilization",
            "ClusterName", aws_ecs_cluster.main.name,
          "ServiceName", aws_ecs_service.app.name]]
        }
      },
      {
        type = "metric"
        properties = {
          title  = "ALB Request Count"
          region = var.aws_region
          period = 60
          stat   = "Sum"
          metrics = [["AWS/ApplicationELB", "RequestCount",
          "LoadBalancer", aws_lb.main.arn_suffix]]
        }
      }
    ]
  })
}

# ─────────────────────────────────────────
# AUTO SCALING
# ─────────────────────────────────────────

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_up" {
  name               = "${var.project_name}-scale-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_down" {
  name               = "${var.project_name}-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_scale_up" {
  alarm_name          = "${var.project_name}-cpu-scale-up"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_up.arn]
  tags          = { Project = var.project_name, CanDelete = "yes" }
}

resource "aws_cloudwatch_metric_alarm" "cpu_scale_down" {
  alarm_name          = "${var.project_name}-cpu-scale-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_down.arn]
  tags          = { Project = var.project_name, CanDelete = "yes" }
}
