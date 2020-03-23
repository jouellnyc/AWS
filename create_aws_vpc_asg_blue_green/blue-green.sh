#!/bin/bash

# Given an AWS Web app behind an ALB, flip the Target Groups from GREEN to BLUE and back

export PORT1="80"
export PORT2="443"

# 1. Required - List the name of the Load Balancer
source ../shared_vars.txt

# 2. Required - List the name of the *** NEW *** Target Group Name
export TG_NAME=$1
#export TG_NAME="Target-GRP-Auto-Scale-BLUE"
#export TG_NAME="Target-GRP-Auto-Scale-GREEN"

# Do not touch below here #

export LB_ARN=$(aws elbv2  describe-load-balancers --name $LB_NAME --query 'LoadBalancers[0].{Arn:LoadBalancerArn}' --output text)

export LST_ARN1=$(aws elbv2 describe-listeners --load-balancer-arn  $LB_ARN \
--query 'Listeners[?Port==`'$PORT1'`].ListenerArn'  --output text)

#There is no ssl right now..
#export LST_ARN2=$(aws elbv2 describe-listeners --load-balancer-arn  $LB_ARN \
# --query 'Listeners[?Port==`'$PORT2'`].ListenerArn' --output text)

export TG_ARN=$(aws elbv2  describe-target-groups --query \
'TargetGroups[?TargetGroupName==`'$TG_NAME'`].{ARN:TargetGroupArn}' --output text)

if aws elbv2 modify-listener --listener-arn $LST_ARN1 --default-actions Type=forward,TargetGroupArn=$TG_ARN --output json\
| grep -iq \/$TG_NAME\/; then
  echo "Target updated to  $TG_NAME"
fi


#There is no ssl right now..
#aws elbv2 modify-listener --listener-arn $LST_ARN2 --default-actions Type=forward,TargetGroupArn=$TG_ARN


###########
# Init deploy
#../update_auto_scaling/update_auto_scaling.sh   Auto-Scaling-GRP-GREEN 2 2 
#### Time passes..You now wan to upgrade .... 
#../update_auto_scaling/update_auto_scaling.sh   Auto-Scaling-GRP-BLUE  2 2 
#### Test Blue ... If if passes:
#./blue-green.sh  "Target-GRP-Auto-Scale-GREEN"
#../update_auto_scaling/update_auto_scaling.sh   Auto-Scaling-GRP-GREEN 0 0  
