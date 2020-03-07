#!/bin/bash

source ../shared_vars.txt  >/dev/null 2>&1  || { echo 'no shared vars'; exit 55; }

export PORT="80"
export PROTO="HTTP"

####EC2 INSTANCES
# 1. Create an Auto Scaling Launch Configuation 
export TYPE="t2.micro"
export AMI="ami-01bbe152bf19d0289"
export USERDATA="user_data.http.sh"
export SCALEJSON="cpu.json"
[ -f $USERDATA ] || { echo "No user data"; exit 55; }

aws autoscaling create-launch-configuration --launch-configuration-name $LC_NAME \
--instance-type $TYPE --key-name $KEYPAIR --security-groups \
$EC2FROMLB $LBFROMMYIP $LBFROMEC2S $SSH  --user-data file://$USERDATA \
--image-id $AMI --iam-instance-profile  $INST_PROF \
&& echo "Created AutoScaling Config OK"
sleep 3

#### BLUE SIDE  ###
#2ai. Create Target Groups for Auto Scaling use
aws elbv2 create-target-group  --name "${TG_NAME_A}" --protocol $PROTO --port $PORT --vpc-id $VPCID
export TG_ARN=$(aws elbv2  describe-target-groups --query \
'TargetGroups[?TargetGroupName==`'$TG_NAME_A'`].{ARN:TargetGroupArn}' --output text) && echo "Created $TG_NAME_A  OK"
sleep 3

#2aii. Create Auto Scaling Groups and attach Target Group
export MIN_SERVERS=0
export MAX_SERVERS=0
export DESIRED=0

aws autoscaling create-auto-scaling-group --auto-scaling-group-name "${ASG_NAME_A}" \
    --launch-configuration-name "${LC_NAME}" --target-group-arns $TG_ARN            \
    --min-size $MIN_SERVERS --max-size $MAX_SERVERS  --desired-capacity $DESIRED    \
    --vpc-zone-identifier $SUBNET1,$SUBNET2 &&                                      \ 
aws autoscaling put-scaling-policy --policy-name $ASP_NAME --auto-scaling-group-name \
    $ASG_NAME_A --policy-type TargetTrackingScaling --target-tracking-configuration file://$SCALEJSON && \
    echo "Created $ASG_NAME_A  and Policies OK"
sleep 3

#### /BLUE  ###

#### GREEN ####
#2bi. Create Target Group for Auto Scaling use
aws elbv2 create-target-group  --name "${TG_NAME_B}" --protocol $PROTO --port $PORT --vpc-id $VPCID
export TG_ARN=$(aws elbv2  describe-target-groups --query \
    'TargetGroups[?TargetGroupName==`'$TG_NAME_B'`].{ARN:TargetGroupArn}' --output text) && echo "Created $TG_NAME_B  OK"
sleep 3

#2bii.  Create Auto Scaling Groups and attach Target Group
export MIN_SERVERS=1
export MAX_SERVERS=3
export DESIRED=2
[ -f $SCALEJSON ] || { echo "No Scale Policy File"; }
aws autoscaling create-auto-scaling-group --auto-scaling-group-name "${ASG_NAME_B}" \
    --launch-configuration-name "${LC_NAME}" --target-group-arns $TG_ARN          \
    --min-size $MIN_SERVERS --max-size $MAX_SERVERS  --desired-capacity $DESIRED  \
    --vpc-zone-identifier $SUBNET1,$SUBNET2 && \ 
aws autoscaling put-scaling-policy --policy-name $ASP_NAME --auto-scaling-group-name \
    $ASG_NAME_B --policy-type TargetTrackingScaling --target-tracking-configuration file://$SCALEJSON && \
    echo "Created $ASG_NAME_B  and Policies OK"
sleep 3
#### /GREEN ####

#3. Create Load Balancer and attach Auto Scaling Group to GREEN first at init time
aws elbv2 create-load-balancer --name $LB_NAME --subnets $SUBNET1 $SUBNET2  --security-groups  $LBFROMMYIP && \
export LB_ARN=$(aws elbv2  describe-load-balancers --name $LB_NAME --query 'LoadBalancers[0].{Arn:LoadBalancerArn}' --output text) && \
aws elbv2 create-listener  --load-balancer-arn $LB_ARN --protocol $PROTO --port $PORT --default-actions Type=forward,TargetGroupArn=$TG_ARN && \
echo "Created LoadBalancer and Listener OK"
