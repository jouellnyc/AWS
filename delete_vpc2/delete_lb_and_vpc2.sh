#!/bin/bash

# Delete all the Resource after running:

source ../shared_vars.txt

echo "Waiting 2 min for Auto Scaling Config to be deleted..."
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME_A  --no-new-instances-protected-from-scale-in
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME_B  --no-new-instances-protected-from-scale-in
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $ASG_NAME_A  --force-delete
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $ASG_NAME_B  --force-delete
sleep 120

INSTANCES=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId]' --filters Name=instance-state-name,Values=running --output text)
for instance  in $(echo $INSTANCES); do 
    aws ec2 terminate-instances --instance-ids $instance  && echo "Terminating $instance OK"
    sleep 3
done 

LB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn' --output text)
aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN
sleep 5

export TG_ARN_A=$(aws elbv2  describe-target-groups --query \
'TargetGroups[?TargetGroupName==`'$TG_NAME_A'`].{ARN:TargetGroupArn}' --output text)
export TG_ARN_B=$(aws elbv2  describe-target-groups --query \
'TargetGroups[?TargetGroupName==`'$TG_NAME_B'`].{ARN:TargetGroupArn}' --output text)

aws elbv2 delete-target-group --target-group-arn $TG_ARN_A
sleep 5
aws elbv2 delete-target-group --target-group-arn $TG_ARN_B
sleep 5

aws autoscaling delete-launch-configuration --launch-configuration-name $LC_NAME
echo "Waiting 120s for Launch Config to be deleted..."

SUBNET1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR1" --query 'Subnets[*].{ID:SubnetId}' --output text)
SUBNET2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR2" --query 'Subnets[*].{ID:SubnetId}' --output text)

aws ec2 delete-subnet --subnet-id  $SUBNET1
aws ec2 delete-subnet --subnet-id  $SUBNET2
echo "Waiting 30s for Security Groups dependencies to be deleted 1 ..."
sleep 30

IGWID=$(aws ec2 describe-internet-gateways --query 'InternetGateways[0].InternetGatewayId' --output text)
aws ec2 detach-internet-gateway --internet-gateway-id $IGWID --vpc-id $VPCID
aws ec2 delete-internet-gateway --internet-gateway-id $IGWID && echo "IGW Deleted"
echo "Waiting for Security Groups dependencies to be deleted 2 ..."
sleep 60  

#LBFROMMYIP can fail if not waiting long enough
for x in $(aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupId]' --output text); do
  aws ec2 delete-security-group --group-id $x 
done

aws ec2 delete-key-pair --key-name $KEYPAIR 
aws ec2 delete-vpc --vpc-id  $VPCID  && echo "VPC deleted OK"
