#!/bin/bash

source ../shared_vars.txt  >/dev/null 2>&1  || { echo 'no shared vars'; exit 55; }

export PORT="80"
export PROTO="HTTP"

export WEB_SRV="nginx"
export WEB_APP="flask"
export DB="mongodb"

####IAM
# Create instance profile
if ! aws iam list-instance-profiles --output json | grep -i InstanceProfileName | grep -q $INST_PROF; then
  aws iam create-instance-profile --instance-profile-name $INST_PROF 
  sleep 5
fi


# Create EC2 Role
if ! aws iam get-role --role-name $APP_ROLE  2>/dev/null; then
  aws iam create-role --role-name $APP_ROLE --assume-role-policy-document file://../IAM/iam.trustpolicyforec2.json
fi

sleep 15

#Ensure role is attached to Instance Profile
if ! aws iam list-instance-profiles --output json | grep Roles -i $APP_ROLE  then
  aws iam add-role-to-instance-profile --role-name $APP_ROLE --instance-profile-name $INST_PROF 
  sleep 5
fi

# Populate the Role with Polices for Cloud Watch and AWS Secret Mgr
if ! aws iam list-policies  --output json --scope Local | grep -q $CW_POLICY; then
  CW_FILE="../IAM/iam.cloudwatch.json"
  aws iam create-policy --policy-name $CW_POLICY  --policy-document file://$CW_FILE
  aws iam put-role-policy --role-name $APP_ROLE  --policy-name  $CW_POLICY --policy-document file://$CW_FILE
fi
if ! aws iam list-policies  --output json --scope Local | grep -q $AS_POLICY; then
  AS_FILE="../IAM/iam.aws_secrets_mgr.json"
  aws iam create-policy --policy-name $AS_POLICY  --policy-document file://$AS_FILE
  aws iam put-role-policy --role-name $APP_ROLE  --policy-name  $AS_POLICY --policy-document file://$AS_FILE
  sleep 5
fi

# Create CloudWatch log groups
for log_group in $WEB_SRV $WEB_APP $DB; do 

if !  aws logs describe-log-groups --log-group-name-prefix $log_group --output json | grep -q logGroupName;then
    aws logs create-log-group --log-group-name $log_group
fi

done

####EC2 INSTANCES
# 1. Create an Auto Scaling Launch Configuation 
export TYPE="t2.micro"
export AMI="ami-0fc61db8544a617ed"
export USERDATA="/home/john/gitrepos/shouldipickitup/user_data.http.AWS.sh"
export SCALEJSON="cpu.json"
[ -f $USERDATA ] || { echo "No user data"; exit 55; }

aws autoscaling create-launch-configuration --launch-configuration-name $LC_NAME \
--instance-type $TYPE --key-name $KEYPAIR --security-groups \
$EC2FROMLB $LBFROMMYIP $LBFROMEC2S $SSH  --user-data file://$USERDATA \
--image-id $AMI --iam-instance-profile  $INST_PROF \
&& echo "Created AutoScaling Launch Config OK"
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
export MAX_SERVERS=1
export DESIRED=1
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
