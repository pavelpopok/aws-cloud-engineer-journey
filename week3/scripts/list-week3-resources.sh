#!/bin/bash

echo "=== Week 3 Resources ==="
echo ""

echo "VPCs:"
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=Week3" \
  --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
  --output table

echo ""
echo "Subnets:"
aws ec2 describe-subnets \
  --filters "Name=tag:Project,Values=Week3" \
  --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' \
  --output table

echo ""
echo "Internet Gateways:"
aws ec2 describe-internet-gateways \
  --filters "Name=tag:Project,Values=Week3" \
  --query 'InternetGateways[*].[InternetGatewayId,Tags[?Key==`Name`].Value|[0]]' \
  --output table

echo ""
echo "Route Tables:"
aws ec2 describe-route-tables \
  --filters "Name=tag:Project,Values=Week3" \
  --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0]]' \
  --output table

echo ""
echo "NAT Gateways:"
aws ec2 describe-nat-gateways \
  --filter "Name=tag:Project,Values=Week3" \
  --query 'NatGateways[*].[NatGatewayId,State,Tags[?Key==`Name`].Value|[0]]' \
  --output table

echo ""
echo "EC2 Instances:"
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=Week3" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table

echo ""
echo "Security Groups:"
aws ec2 describe-security-groups \
  --filters "Name=tag:Project,Values=Week3" \
  --query 'SecurityGroups[*].[GroupId,GroupName,Description]' \
  --output table
