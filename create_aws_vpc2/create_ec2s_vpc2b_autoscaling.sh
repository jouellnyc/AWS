#!/bin/bash

################################################################################
# create_ec2s_autoscaling_vpc2b.sh - https://github.com/jouellnyc/AWS          #
################################################################################

source ../shared_vars.txt  >/dev/null 2>&1  || source ./shared_vars.txt 

####EC2 INSTANCES
#Create an Auto Scaling Launch Configuation 
export TYPE="t2.micro"
export AMI="ami-01bbe152bf19d0289"
export USERDATA="../user_data.http.sh"
[ -f $USERDATA ] || { echo "No user data"; exit 55; }

aws autoscaling create-launch-configuration --launch-configuration-name $LC_NAME \
    --instance-type $TYPE --key-name $KEYPAIR --security-groups $EC2FROMLB       \
    --user-data file://$USERDATA --image-id $AMI && echo "Created AutoScaling Config OK"
sleep 3

#### BLUE  ###
#Create Target Group for Auto Scaling use
export TG_NAME="Target-GRP-Auto-Scale-BLUE"
aws elbv2 create-target-group  --name "${TG_NAME}" --protocol $PROTO --port $PORT --vpc-id $VPCID
export TG_ARN=$(aws elbv2  describe-target-groups --query \
    'TargetGroups[?TargetGroupName==`'$TG_NAME'`].{ARN:TargetGroupArn}' --output text) && \
    echo "Created $TG_NAME  OK"
sleep 3

#Create Auto Scaling Groups and attach Target Group
export MIN_SERVERS=0
export MAX_SERVERS=0
export DESIRED=0
export ASG_NAME="Auto-Scaling-GRP-BLUE"
aws autoscaling create-auto-scaling-group --auto-scaling-group-name "${ASG_NAME}" \
    --launch-configuration-name "${LC_NAME}" --target-group-arns $TG_ARN          \
    --min-size $MIN_SERVERS --max-size $MAX_SERVERS  --desired-capacity $DESIRED  \
    --vpc-zone-identifier $SUBNET1,$SUBNET2 && \ 
aws autoscaling put-scaling-policy --policy-name $ASP_NAME --auto-scaling-group-name \
    $ASG_NAME --policy-type TargetTrackingScaling --target-tracking-configuration file://$SCALEJSON && \
    echo "Created $ASG_NAME  and Policies OK"
sleep 3

#### /BLUE  ###

#### GREEN ####
#Create Target Group for Auto Scaling use
export PORT="80"
export PROTO="HTTP"
export TG_NAME="Target-GRP-Auto-Scale-GREEN"
aws elbv2 create-target-group  --name "${TG_NAME}" --protocol $PROTO --port $PORT --vpc-id $VPCID
export TG_ARN=$(aws elbv2  describe-target-groups --query \
    'TargetGroups[?TargetGroupName==`'$TG_NAME'`].{ARN:TargetGroupArn}' --output text) && \
    echo "Created $TG_NAME  OK"
sleep 3

#Create Auto Scaling Groups and attach Target Group
export MIN_SERVERS=1
export MAX_SERVERS=3
export DESIRED=2
export ASG_NAME="Auto-Scaling-GRP-GREEN"
export ASP_NAME="cpu-alert"
export SCALEJSON="cpu.json"
[ -f $SCALEJSON ] || { echo "No Scale Policy File"; }
aws autoscaling create-auto-scaling-group --auto-scaling-group-name "${ASG_NAME}" \
    --launch-configuration-name "${LC_NAME}" --target-group-arns $TG_ARN          \
    --min-size $MIN_SERVERS --max-size $MAX_SERVERS  --desired-capacity $DESIRED  \
    --vpc-zone-identifier $SUBNET1,$SUBNET2 && \ 
aws autoscaling put-scaling-policy --policy-name $ASP_NAME --auto-scaling-group-name \
    $ASG_NAME --policy-type TargetTrackingScaling --target-tracking-configuration file://$SCALEJSON && \
    echo "Created $ASG_NAME  and Policies OK"
sleep 3
#### /GREEN ####

#Create Load Balancer and attach Auto Scaling Group to GREEN first at init time
export LB_NAME="My-Web-Load-Balancer"
aws elbv2 create-load-balancer --name $LB_NAME --subnets $SUBNET1 $SUBNET2  --security-groups  $LBFROMMYIP && \
export LB_ARN=$(aws elbv2  describe-load-balancers --name $LB_NAME --query 'LoadBalancers[0].{Arn:LoadBalancerArn}' --output text) && \
aws elbv2 create-listener  --load-balancer-arn $LB_ARN --protocol $PROTO --port $PORT --default-actions Type=forward,TargetGroupArn=$TG_ARN && \
echo "Created LoadBalancer and Listener OK"
