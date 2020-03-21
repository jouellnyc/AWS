#!/bin/bash

source ../shared_vars.txt

aws elbv2 create-load-balancer --name $LB_NAME --subnets $SUBNET1 $SUBNET2  --security-groups  $LBFROMMYIP
aws elbv2 create-target-group  --name $LB_TGT_NAME --protocol HTTP --port 80 --vpc-id $VPCID
export LB_ARN=$(aws elbv2  describe-load-balancers --name $LB_NAME --query 'LoadBalancers[0].{Arn:LoadBalancerArn}' --output text)
export TGT_ARN=$(aws elbv2  describe-target-groups  --query 'TargetGroups[?TargetGroupName==`'$LB_TGT_NAME'`].{ARN:TargetGroupArn}' --output text)

#export INSTANCE1=$(aws ec2 describe-instances  --filters "Name=vpc-id,Values=$VPCID" --query 'Reservations[0].Instances[0].InstanceId' --output text)
#export INSTANCE2=$(aws ec2 describe-instances  --filters "Name=vpc-id,Values=$VPCID" --query 'Reservations[1].Instances[0].InstanceId' --output text)

#aws elbv2 register-targets --target-group-arn  $TGT_ARN --targets Id=$INSTANCE1 Id=$INSTANCE2
aws elbv2 create-listener  --load-balancer-arn $LB_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TGT_ARN
aws elbv2 create-listener  --load-balancer-arn $LB_ARN --protocol HTTP --port 443 --default-actions Type=forward,TargetGroupArn=$TGT_ARN
aws elbv2 describe-target-health --target-group-arn  $TGT_ARN
