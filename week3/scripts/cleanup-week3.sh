#!/bin/bash

echo "=== Week 3 Cleanup Script ==="
echo ""
echo "This will delete ALL resources tagged with Project=Week3"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

echo ""
echo "Step 1: Terminating EC2 instances..."
INSTANCES=$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=Week3" "Name=instance-state-name,Values=running,stopped" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text)

if [ -n "$INSTANCES" ]; then
    echo "Found instances: $INSTANCES"
    aws ec2 terminate-instances --instance-ids $INSTANCES
    echo "Waiting for instances to terminate..."
    aws ec2 wait instance-terminated --instance-ids $INSTANCES
    echo "✓ Instances terminated"
else
    echo "No instances to terminate"
fi

echo ""
echo "Step 2: Deleting NAT Gateways..."
NAT_GWS=$(aws ec2 describe-nat-gateways \
  --filter "Name=tag:Project,Values=Week3" "Name=state,Values=available" \
  --query 'NatGateways[*].NatGatewayId' \
  --output text)

if [ -n "$NAT_GWS" ]; then
    for nat in $NAT_GWS; do
        echo "Deleting NAT Gateway: $nat"
        aws ec2 delete-nat-gateway --nat-gateway-id $nat
    done
    echo "Waiting for NAT Gateways to delete (this takes ~2 minutes)..."
    sleep 120
    echo "✓ NAT Gateways deleted"
else
    echo "No NAT Gateways to delete"
fi

echo ""
echo "Step 3: Releasing Elastic IPs..."
EIP_ALLOCS=$(aws ec2 describe-addresses \
  --filters "Name=tag:Project,Values=Week3" \
  --query 'Addresses[*].AllocationId' \
  --output text)

if [ -n "$EIP_ALLOCS" ]; then
    for eip in $EIP_ALLOCS; do
        echo "Releasing EIP: $eip"
        aws ec2 release-address --allocation-id $eip
    done
    echo "✓ Elastic IPs released"
else
    echo "No Elastic IPs to release"
fi

echo ""
echo "Step 4: Detaching and deleting Internet Gateways..."
IGWS=$(aws ec2 describe-internet-gateways \
  --filters "Name=tag:Project,Values=Week3" \
  --query 'InternetGateways[*].[InternetGatewayId,Attachments[0].VpcId]' \
  --output text)

if [ -n "$IGWS" ]; then
    while read -r igw vpc; do
        if [ -n "$vpc" ]; then
            echo "Detaching IGW $igw from VPC $vpc"
            aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc
        fi
        echo "Deleting IGW $igw"
        aws ec2 delete-internet-gateway --internet-gateway-id $igw
    done <<< "$IGWS"
    echo "✓ Internet Gateways deleted"
else
    echo "No Internet Gateways to delete"
fi

echo ""
echo "Step 5: Deleting Subnets..."
SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=tag:Project,Values=Week3" \
  --query 'Subnets[*].SubnetId' \
  --output text)

if [ -n "$SUBNETS" ]; then
    for subnet in $SUBNETS; do
        echo "Deleting subnet: $subnet"
        aws ec2 delete-subnet --subnet-id $subnet
    done
    echo "✓ Subnets deleted"
else
    echo "No subnets to delete"
fi

echo ""
echo "Step 6: Deleting Route Tables..."
RTS=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Project,Values=Week3" \
  --query 'RouteTables[*].RouteTableId' \
  --output text)

if [ -n "$RTS" ]; then
    for rt in $RTS; do
        echo "Deleting route table: $rt"
        aws ec2 delete-route-table --route-table-id $rt 2>/dev/null || echo "  (might be main route table, skipping)"
    done
    echo "✓ Route tables deleted"
else
    echo "No route tables to delete"
fi

echo ""
echo "Step 7: Deleting Security Groups..."
SGS=$(aws ec2 describe-security-groups \
  --filters "Name=tag:Project,Values=Week3" \
  --query 'SecurityGroups[*].GroupId' \
  --output text)

if [ -n "$SGS" ]; then
    for sg in $SGS; do
        echo "Deleting security group: $sg"
        aws ec2 delete-security-group --group-id $sg 2>/dev/null || echo "  (might be default or in use, skipping)"
    done
    echo "✓ Security groups deleted"
else
    echo "No security groups to delete"
fi

echo ""
echo "Step 8: Deleting VPC..."
VPCS=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=Week3" \
  --query 'Vpcs[*].VpcId' \
  --output text)

if [ -n "$VPCS" ]; then
    for vpc in $VPCS; do
        echo "Deleting VPC: $vpc"
        aws ec2 delete-vpc --vpc-id $vpc
    done
    echo "✓ VPCs deleted"
else
    echo "No VPCs to delete"
fi

echo ""
echo "=== Cleanup Complete ==="
echo "Run ~/list-week3-resources.sh to verify everything is gone"
