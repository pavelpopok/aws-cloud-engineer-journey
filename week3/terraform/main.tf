# ============================================
# TERRAFORM CONFIGURATION
# ============================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================
# AWS PROVIDER
# ============================================

provider "aws" {
  region = "eu-central-1"
}

# ============================================
# VPC
# ============================================

resource "aws_vpc" "week3" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "week3-vpc-terraform"
    Project   = "Week3-Terraform"
    CanDelete = "Yes"
  }
}

# ============================================
# INTERNET GATEWAY
# ============================================

resource "aws_internet_gateway" "week3" {
  vpc_id = aws_vpc.week3.id

  tags = {
    Name      = "week3-igw-terraform"
    Project   = "Week3-Terraform"
    CanDelete = "Yes"
  }
}

# ============================================
# PUBLIC SUBNETS
# ============================================

resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.week3.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "week3-public-1a-terraform"
    Project   = "Week3-Terraform"
    Type      = "Public"
    CanDelete = "Yes"
  }
}

resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.week3.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name      = "week3-public-1b-terraform"
    Project   = "Week3-Terraform"
    Type      = "Public"
    CanDelete = "Yes"
  }
}

# ============================================
# ADDITIONAL PUBLIC SUBNET
# ============================================

resource "aws_subnet" "public_1c" {
  vpc_id                  = aws_vpc.week3.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-central-1c"
  map_public_ip_on_launch = true

  tags = {
    Name      = "week3-public-1c-terraform"
    Project   = "Week3-Terraform"
    Type      = "Public"
    CanDelete = "Yes"
  }
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

# ============================================
# PRIVATE SUBNETS
# ============================================

resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.week3.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name      = "week3-private-1a-terraform"
    Project   = "Week3-Terraform"
    Type      = "Private"
    CanDelete = "Yes"
  }
}

resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.week3.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name      = "week3-private-1b-terraform"
    Project   = "Week3-Terraform"
    Type      = "Private"
    CanDelete = "Yes"
  }
}

# ============================================
# PUBLIC ROUTE TABLE
# ============================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.week3.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.week3.id
  }

  tags = {
    Name      = "week3-public-rt-terraform"
    Project   = "Week3-Terraform"
    CanDelete = "Yes"
  }
}

# ============================================
# ROUTE TABLE ASSOCIATIONS
# ============================================

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public.id
}

# ============================================
# OUTPUTS
# ============================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.week3.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.week3.cidr_block
}

output "public_subnet_1a_id" {
  description = "The ID of public subnet 1a"
  value       = aws_subnet.public_1a.id
}

output "public_subnet_1b_id" {
  description = "The ID of public subnet 1b"
  value       = aws_subnet.public_1b.id
}

output "private_subnet_1a_id" {
  description = "The ID of private subnet 1a"
  value       = aws_subnet.private_1a.id
}

output "private_subnet_1b_id" {
  description = "The ID of private subnet 1b"
  value       = aws_subnet.private_1b.id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.week3.id
}
