#!/bin/bash

# Given an AWS Web app behind an ALB, flip the Target Groups from GREEN to BLUE and back

export PORT1="80"
export PORT2="443"

# 1. Required - List the name of the Load Balancer
export LB_NAME="My-Web-Load-Balancer"

# 2. Required - List the name of the Target Group Name
export TG_NAME="Target-Group-Auto-Scaling-BLUE"
export TG_NAME="Target-Group-Auto-Scaling-GREEN"

# Do not touch below here #

export LB_ARN=$(aws elbv2  describe-load-balancers --name $LB_NAME --query 'LoadBalancers[0].{Arn:LoadBalancerArn}' --output text)

export LST_ARN1=$(aws elbv2 describe-listeners --load-balancer-arn  $LB_ARN \
--query 'Listeners[?Port==`'$PORT1'`].ListenerArn'  --output text)
export LST_ARN2=$(aws elbv2 describe-listeners --load-balancer-arn  $LB_ARN \
 --query 'Listeners[?Port==`'$PORT2'`].ListenerArn' --output text)

export TG_ARN=$(aws elbv2  describe-target-groups --query \
'TargetGroups[?TargetGroupName==`'$TG_NAME'`].{ARN:TargetGroupArn}' --output text)

aws elbv2 modify-listener --listener-arn $LST_ARN1 --default-actions Type=forward,TargetGroupArn=$TG_ARN
aws elbv2 modify-listener --listener-arn $LST_ARN2 --default-actions Type=forward,TargetGroupArn=$TG_ARN
