#!/bin/bash


#Create an Auto Scaling Launch Configuation 
export TYPE="t2.micro"
export AMI="ami-01bbe152bf19d0289"
export LC_NAME="Auto-Scaling-Launch-Config"
export USERDATA="../user_data.http.sh"
[ -f $USERDATA ] || { echo "No user data"; exit 55; }

aws autoscaling create-launch-configuration --launch-configuration-name $LC_NAME \
    --image-id $AMI --instance-type $TYPE --key-name $KEYPAIR --user-data file://$USERDATA

#Create Target Group for Auto Scaling use
export PORT="80"
export PROTO="HTTP"
export TG_NAME="Target-Group-for-Auto-Scaling"
aws elbv2 create-target-group  --name "${TG_NAME}" --protocol $PROTO --port $PORT --vpc-id $VPCID
export TG_ARN=$(aws elbv2  describe-target-groups --query \
    'TargetGroups[?TargetGroupName==`'$TG_NAME'`].{ARN:TargetGroupArn}' --output text)


#Create Auto Scaling Group and attach Target Group
export MIN_SERVERS=1
export MAX_SERVERS=3
export ASG_NAME="Auto-Scaling-Group"
aws autoscaling create-auto-scaling-group --auto-scaling-group-name "${ASG_NAME}" \
    --launch-configuration-name "${LC_NAME}" --target-group-arns $TG_ARN          \
    --min-size $MIN_SERVERS --max-size $MAX_SERVERS  --vpc-zone-identifier $SUBNET1,$SUBNET2 

#Create Load Balancer and attach Auto Scaling Group
export LB_NAME="My-Web-load-balancer"
aws elbv2 create-load-balancer --name $LB_NAME --subnets $SUBNET1 $SUBNET2  --security-groups  $LBFROMMYIP
export LB_ARN=$(aws elbv2  describe-load-balancers --name $LB_NAME --query 'LoadBalancers[0].{Arn:LoadBalancerArn}' --output text)
aws elbv2 create-listener  --load-balancer-arn $LB_ARN --protocol $PROTO --port $PORT --default-actions Type=forward,TargetGroupArn=$TGT_ARN
aws autoscaling attach-load-balancers --auto-scaling-group-name $ASG_NAME --load-balancer-names $LB_NAME 
