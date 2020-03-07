#!/bin/bash

# Delete all the Resource after running:

source ../shared_vars.txt

aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME_A \
--min-size 0  --max-size 0  --launch-configuration-name $LC_NAME 
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME_B \
--min-size 0  --max-size 0  --launch-configuration-name $LC_NAME 

aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME_A  --no-new-instances-protected-from-scale-in
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $ASG_NAME_A  --force-delete
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME_B  --no-new-instances-protected-from-scale-in
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $ASG_NAME_B  --force-delete
echo "aws autoscaling  describe-scaling-activities  --max-items 1"
echo "Waiting 3 min for Auto Scaling Config to be deleted..."
sleep 180

export TG_ARN_A=$(aws elbv2  describe-target-groups --query \
'TargetGroups[?TargetGroupName==`'$TG_NAME_A'`].{ARN:TargetGroupArn}' --output text)
export TG_ARN_B=$(aws elbv2  describe-target-groups --query \
'TargetGroups[?TargetGroupName==`'$TG_NAME_B'`].{ARN:TargetGroupArn}' --output text)


aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN
echo "Waiting 30s  for LB to be deleted..."
sleep 30 
aws elbv2 delete-target-group --target-group-arn $TG_ARN_A
aws elbv2 delete-target-group --target-group-arn $TG_ARN_B
aws autoscaling delete-launch-configuration --launch-configuration-name $LC_NAME
echo "Waiting 30s for Launch Config to be deleted..."
sleep 30  

SUBNET1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR1" --query 'Subnets[*].{ID:SubnetId}' --output text)
SUBNET2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR2" --query 'Subnets[*].{ID:SubnetId}' --output text)

aws ec2 delete-subnet --subnet-id  $SUBNET1
aws ec2 delete-subnet --subnet-id  $SUBNET2
echo "Waiting 30s for Security Groups dependencies to be deleted 1 ..."
sleep 30

aws ec2 detach-internet-gateway --internet-gateway-id $IGWID --vpc-id $VPCID
aws ec2 delete-internet-gateway --internet-gateway-id $IGWID
echo "Waiting 60s for Security Groups dependencies to be deleted 2 ..."
sleep 60  
aws ec2 delete-security-group --group-id $LBFROMMYIP
aws ec2 delete-security-group --group-id $EC2FROMLB 
aws ec2 delete-security-group --group-id $LBFROMEC2S

aws ec2 delete-key-pair --key-name $KEYPAIR 
aws ec2 delete-vpc --vpc-id  $VPCID  && echo "VPC deleted OK"
