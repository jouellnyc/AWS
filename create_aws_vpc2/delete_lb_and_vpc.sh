#!/bin/bash

# Delete all the Resource after running:
# source create_aws_vpc2.sh && create_ec2s_autoscaling_vpc2b.sh

aws autoscaling update-auto-scaling-group --auto-scaling-group-name Auto-Scaling-Group --no-new-instances-protected-from-scale-in
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name Auto-Scaling-Group --force-delete
echo "Waiting 3 min for Auto Scaling Config to be deleted..."
sleep 180
INSTANCES=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId]' --filters Name=instance-state-name,Values=running --output text)
for instance  in $(echo $INSTANCES); do 
    aws ec2 terminate-instances --instance-ids $instance  && echo "Terminating $instance OK"
done 

aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN
echo "Waiting 30s  for LB to be deleted..."
sleep 30 
aws elbv2 delete-target-group --target-group-arn $TG_ARN
aws autoscaling delete-launch-configuration --launch-configuration-name $LC_NAME
echo "Waiting 30s for Launch Config to be deleted..."
sleep 30  

SUBNET1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR1" --query 'Subnets[*].{ID:SubnetId}' --output text)
SUBNET2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR2" --query 'Subnets[*].{ID:SubnetId}' --output text)

aws ec2 delete-subnet --subnet-id  $SUBNET1
aws ec2 delete-subnet --subnet-id  $SUBNET2
echo "Waiting for Security Groups dependencies to be deleted 1 ..."
sleep 30

aws ec2 detach-internet-gateway --internet-gateway-id $IGWID --vpc-id $VPCID
aws ec2 delete-internet-gateway --internet-gateway-id $IGWID
echo "Waiting for Security Groups dependencies to be deleted 2 ..."
sleep 30 

aws ec2 delete-security-group --group-id $LBFROMMYIP
aws ec2 delete-security-group --group-id $EC2FROMLB 
aws ec2 delete-security-group --group-id $LBFROMEC2S

aws ec2 delete-key-pair --key-name $KEYPAIR 
#RTID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPCID" --query "RouteTables[].RouteTableId[]" --output text)
#Cannot delete default routes specifically but can via the whole VPC
#aws ec2 delete-route --route-table-id $RTID --destination-cidr-block $VPCCIDR 
#aws ec2 delete-route-table --route-table-id $RTID 
aws ec2 delete-vpc --vpc-id  $VPCID  && echo "VPC deleted OK"
