# DATA SOURCES
data "aws_secretsmanager_secret_version" "db" {
  secret_id = "week8/rds/credentials"
}
# ---------------------------------------------------------------------------
#
# IAM Role for ECS Task Execution
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
# ---------------------------------------------------------------------------
#
# Base ECS execution permissions (ECR pull + CloudWatch logs)
resource "aws_iam_role_policy_attachment" "ecs_execution_base" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# ---------------------------------------------------------------------------
#
# Additional policy for Secrets Manager + Parameter Store access
resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.project_name}-secrets-access"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:week8/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/week8/*"
      }
    ]
  })
}
# ---------------------------------------------------------------------------
#
# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.project_name}-vpc", Project = var.project_name, CanDelete = "yes" }
}

# ---------------------------------------------------------------------------
#
# SUBNETS
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true # ECS tasks get public IPs to pull ECR images
  tags                    = { Name = "${var.project_name}-public-1", Project = var.project_name, CanDelete = "yes" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public-2", Project = var.project_name, CanDelete = "yes" }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "${var.project_name}-private-1", Project = var.project_name, CanDelete = "yes" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "${var.project_name}-private-2", Project = var.project_name, CanDelete = "yes" }
}

# ---------------------------------------------------------------------------
# INTERNET GATEWAY + ROUTING
#
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

# ---------------------------------------------------------------------------
# SECURITY GROUPS
#
resource "aws_security_group" "alb" {
  name   = "${var.project_name}-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
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
  name   = "${var.project_name}-ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "App traffic from ALB only"
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

resource "aws_security_group" "rds" {
  name   = "${var.project_name}-rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "MySQL from ECS tasks only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-rds-sg", Project = var.project_name, CanDelete = "yes" }
}
# ---------------------------------------------------------------------------
# RDS
#
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  tags       = { Name = "${var.project_name}-db-subnet-group", Project = var.project_name, CanDelete = "yes" }
}

resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20

  db_name  = "week8db"
  username = var.db_username

  password = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)["password"]

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false

  # Learning environment settings
  skip_final_snapshot     = true
  backup_retention_period = 1
  multi_az                = false

  tags = { Name = "${var.project_name}-mysql", Project = var.project_name, CanDelete = "yes" }
}
# ---------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
#
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
  tags              = { Project = var.project_name, CanDelete = "yes" }
}

# ---------------------------------------------------------------------------
# ECS CLUSTER
#
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  tags = { Project = var.project_name, CanDelete = "yes" }
}

# ---------------------------------------------------------------------------
# ECS TASK DEFINITION
#
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name  = "${var.project_name}-container"
    image = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/week8-flask:latest"

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    # SECRETS BLOCK
    secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = "${data.aws_secretsmanager_secret_version.db.arn}:password::"
      },
      {
        name      = "DB_USER"
        valueFrom = "${data.aws_secretsmanager_secret_version.db.arn}:username::"
      }
    ]

    # ENVIRONMENT BLOCK
    environment = [
      {
        name  = "DB_HOST"
        value = aws_db_instance.main.address
      },
      {
        name  = "DB_NAME"
        value = "week8db"
      }
    ]

    # CloudWatch logging
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

# ---------------------------------------------------------------------------
# APPLICATION LOAD BALANCER
#
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  tags               = { Name = "${var.project_name}-alb", Project = var.project_name, CanDelete = "yes" }
}

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

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ---------------------------------------------------------------------------
# ECS SERVICE
#
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
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

  # Explicit dependency
  depends_on = [aws_lb_listener.http]

  tags = { Project = var.project_name, CanDelete = "yes" }
}
