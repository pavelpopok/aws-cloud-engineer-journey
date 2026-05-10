terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-640768198958"
    key            = "week11/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# IAM role — Lambda needs this to write logs to CloudWatch
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-lambda-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = { Project = var.project_name, CanDelete = "yes" }
}

# Managed policy that gives Lambda permission to write to CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# The Lambda function
resource "aws_lambda_layer_version" "common" {
  layer_name          = "${var.project_name}-common"
  filename            = "../layers/common/common-layer.zip"
  compatible_runtimes = ["python3.12"]
  description         = "Common Python dependencies: requests"
}

resource "aws_lambda_function" "hello" {
  function_name = "${var.project_name}-hello"
  role          = aws_iam_role.lambda_execution.arn

  filename      = "../functions/hello/hello.zip"
  source_code_hash = filebase64sha256("../functions/hello/hello.zip")
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 128
  layers = [aws_lambda_layer_version.common.arn]

  environment {
    variables = {
      ENVIRONMENT = var.project_name
    }
  }

  tags = { Project = var.project_name, CanDelete = "yes" }
}

# API Gateway HTTP API (v2) — the public-facing endpoint
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  # CORS — allows browser requests from any origin
  # Without this, browsers block responses from domains that didn't serve the page
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
  }

  tags = { Project = var.project_name, CanDelete = "yes" }
}

# Stage — a named deployment environment
# $default is special: it removes the stage name from the URL path
# Without $default your URL would be: /prod/hello instead of /hello
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  tags = { Project = var.project_name, CanDelete = "yes" }
}

# Resource-based policy — gives API Gateway permission to invoke Lambda
# Without this: API Gateway → Lambda returns 403, your function never runs
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"

  # source_arn format: execution_arn/stage/method/path
  # The /** wildcard covers any stage, any method, any route
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# Integration — wires API Gateway to your Lambda function
resource "aws_apigatewayv2_integration" "hello" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "AWS_PROXY"   # proxy: pass full HTTP request to Lambda as event
  integration_uri    = aws_lambda_function.hello.invoke_arn
  integration_method = "POST"        # API Gateway always uses POST internally to invoke Lambda
                                     # this is not the HTTP method the user sees — that's in the route

  payload_format_version = "2.0"     # v2 event structure — cleaner than v1
}

# Route — maps an HTTP method + path to the integration
resource "aws_apigatewayv2_route" "hello" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.hello.id}"
}

# S3 bucket — this is what triggers the Lambda on uploads
resource "aws_s3_bucket" "uploads" {
  bucket = "${var.project_name}-uploads-${var.aws_account_id}"
  tags   = { Project = var.project_name, CanDelete = "yes" }
}

# Block all public access — this bucket is for Lambda processing only
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM policy — allows Lambda to read files from this specific bucket
resource "aws_iam_role_policy" "lambda_s3_read" {
  name = "${var.project_name}-s3-read"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:HeadObject"]
      Resource = "${aws_s3_bucket.uploads.arn}/*"
    }]
  })
}

# The S3 processor Lambda function
resource "aws_lambda_function" "s3_processor" {
  function_name = "${var.project_name}-s3-processor"
  role          = aws_iam_role.lambda_execution.arn
  filename      = "../functions/s3-processor/s3-processor.zip"
  source_code_hash = filebase64sha256("../functions/s3-processor/s3-processor.zip")
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 128

  environment {
    variables = {
      ENVIRONMENT = var.project_name
    }
  }

  tags = { Project = var.project_name, CanDelete = "yes" }
}

# Resource-based policy — gives S3 permission to invoke this Lambda
# Same concept as the API Gateway permission from Day 2
resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}

# S3 bucket notification — the wire connecting uploads to Lambda
# depends_on is required: the permission must exist before the notification
# otherwise S3 tries to test the Lambda connection and gets a 403
resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }

  depends_on = [aws_lambda_permission.s3_invoke]
}

# IAM policy — allows Lambda to read ECS cluster info
# list_clusters and describe_clusters require * resource
# because they don't operate on a specific ARN — they scan the whole account
resource "aws_iam_role_policy" "lambda_ecs_read" {
  name = "${var.project_name}-ecs-read"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecs:ListClusters",
        "ecs:DescribeClusters",
        "ecs:ListServices"
      ]
      Resource = "*"
    }]
  })
}

# The scheduled Lambda function
# Note: AWS_REGION is reserved — do not set it as an environment variable
resource "aws_lambda_function" "scheduled" {
  function_name = "${var.project_name}-scheduled"
  role          = aws_iam_role.lambda_execution.arn
  filename      = "../functions/scheduled/scheduled.zip"
  source_code_hash = filebase64sha256("../functions/scheduled/scheduled.zip")
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 128

  environment {
    variables = {
      ENVIRONMENT = var.project_name
    }
  }

  tags = { Project = var.project_name, CanDelete = "yes" }
}

# EventBridge rule — the schedule definition
resource "aws_cloudwatch_event_rule" "scheduled_check" {
  name                = "${var.project_name}-scheduled-check"
  description         = "Runs ECS health check every 5 minutes"
  schedule_expression = "rate(60 minutes)"
  state               = "DISABLED"

  tags = { Project = var.project_name, CanDelete = "yes" }
}

# EventBridge target — links the rule to your Lambda
resource "aws_cloudwatch_event_target" "scheduled_lambda" {
  rule      = aws_cloudwatch_event_rule.scheduled_check.name
  target_id = "ScheduledLambda"
  arn       = aws_lambda_function.scheduled.arn
}

# Resource-based policy — gives EventBridge permission to invoke Lambda
resource "aws_lambda_permission" "eventbridge_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled_check.arn
}
