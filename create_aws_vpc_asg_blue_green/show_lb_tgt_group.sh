#!/bin/bash

source ../shared_vars.txt
export LB_ARN=$(aws elbv2  describe-load-balancers --name $LB_NAME --query 'LoadBalancers[0].{Arn:LoadBalancerArn}' --output text)
aws elbv2 describe-listeners --load-balancer-arn  $LB_ARN | grep TargetGroupArn | grep -ioE Target-GRP-Auto-Scale.*+
