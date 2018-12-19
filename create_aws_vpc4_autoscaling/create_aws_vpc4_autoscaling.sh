#!/bin/bash 

########################################################
# create_aws_vpc.sh - https://github.com/jouellnyc/AWS #
########################################################

#set -ue

#AVAIL ZONES
export AZ1=us-west-2a
export AZ2=us-west-2b

#VPC
export VPCLABEL="PROD-VPC44"
export VPCCIDR="10.0.0.0/16"
export VPCID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output text  | grep -ioE "vpc-[A-Za-z0-9]{10,25}")
aws ec2 create-tags --resources $VPCID --tags Key=Name,Value=$VPCLABEL

#SUBNETS
export SNCIDR1="10.0.1.0/24"
export SNCIDR2="10.0.2.0/24"
aws ec2 create-subnet --vpc-id $VPCID --cidr-block $SNCIDR1 --availability-zone  $AZ1
aws ec2 create-subnet --vpc-id $VPCID --cidr-block $SNCIDR2 --availability-zone  $AZ2

#MYIP
export MYIP="104.162.77.49"

############No Need to touch below ###########
sleep 2
export SUBNET1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR1" --query 'Subnets[*].{ID:SubnetId}' --output text)
export SUBNET2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR2" --query 'Subnets[*].{ID:SubnetId}' --output text)
aws ec2 create-tags --resources $SUBNET1  --tags Key=Name,Value=subnet-"${AZ1}"
aws ec2 create-tags --resources $SUBNET2  --tags Key=Name,Value=subnet-"${AZ2}"
aws ec2 modify-subnet-attribute --subnet-id  $SUBNET1 --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id  $SUBNET2 --map-public-ip-on-launch

#IGW
export IGWID=$(aws ec2 create-internet-gateway --output text  | awk  '{ print $2 }')
aws ec2 attach-internet-gateway --vpc-id $VPCID   --internet-gateway-id $IGWID 

#ROUTE TABLE
#aws ec1 create-route-table --vpc-id $VPCID
export RTID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPCID" --query "RouteTables[].RouteTableId[]" --output text)
aws ec2 create-route --route-table-id $RTID  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGWID 
aws ec2 associate-route-table  --subnet-id $SUBNET1 --route-table-id $RTID
aws ec2 associate-route-table  --subnet-id $SUBNET2 --route-table-id $RTID

#KEY PAIRS
#Caution!
###KEY PAIRS
export KEYPAIR="${VPCLABEL}-key.pem"
# Caution!
aws ec2 delete-key-pair --key-name $KEYPAIR
[ -f $KEYPAIR ] && rm -f $KEYPAIR
aws ec2 create-key-pair --key-name $KEYPAIR --query 'KeyMaterial' --output text > $KEYPAIR
chmod 400 $KEYPAIR

###SECURITY GROUPS
export LBFROMMYIP=$(aws ec2 create-security-group --group-name LBFROMMYIP --description "LBfromMYIP" --vpc-id $VPCID --output text)
export LBFROMEC2S=$(aws ec2 create-security-group --group-name LBFROMEC2S --description "LBfromEC2s" --vpc-id $VPCID --output text)
export EC2FROMLB=$(aws ec2 create-security-group --group-name EC2FROMLB --description "EC2fromLB" --vpc-id $VPCID --output text)

#Change "--cidr $MYIP/32" to "--cidr 0.0.0.0/0"  to expose to the Internet at large
aws ec2 authorize-security-group-ingress --group-id $LBFROMMYIP --protocol tcp --port 80 --cidr $MYIP/32
aws ec2 authorize-security-group-ingress --group-id $EC2FROMLB  --protocol tcp --port 80 --source-group $LBFROMMYIP
aws ec2 create-tags --resources $LBFROMMYIP --tags Key=Name,Value="LBFROMMYIP"
aws ec2 create-tags --resources $EC2FROMLB  --tags Key=Name,Value="EC2FROMLB"


####EC2 INSTANCES
#Create an Auto Scaling Launch Configuation 
export TYPE="t2.micro"
export AMI="ami-01bbe152bf19d0289"
export LC_NAME="Auto-Scaling-Launch-Config"
export USERDATA="../user_data.http.sh"
[ -f $USERDATA ] || { echo "No user data"; exit 55; }

aws autoscaling create-launch-configuration --launch-configuration-name $LC_NAME \
    --instance-type $TYPE --key-name $KEYPAIR --security-groups $EC2FROMLB       \
    --user-data file://$USERDATA --image-id $AMI
sleep 3

#Create Target Group for Auto Scaling use
export PORT="80"
export PROTO="HTTP"
export TG_NAME="Target-Group-for-Auto-Scaling"
aws elbv2 create-target-group  --name "${TG_NAME}" --protocol $PROTO --port $PORT --vpc-id $VPCID
export TG_ARN=$(aws elbv2  describe-target-groups --query \
    'TargetGroups[?TargetGroupName==`'$TG_NAME'`].{ARN:TargetGroupArn}' --output text)
sleep 3

#Create Auto Scaling Group and attach Target Group
export MIN_SERVERS=1
export MAX_SERVERS=3
export DESIRED=2
export ASG_NAME="Auto-Scaling-Group"
export ASP_NAME="cpu-alert"
export SCALEJSON="cpu.json"
[ -f $SCALEJSON ] || { echo "No Scale Policy File"; }
aws autoscaling create-auto-scaling-group --auto-scaling-group-name "${ASG_NAME}" \
    --launch-configuration-name "${LC_NAME}" --target-group-arns $TG_ARN          \
    --min-size $MIN_SERVERS --max-size $MAX_SERVERS  --desired-capacity $DESIRED  \
    --vpc-zone-identifier $SUBNET1,$SUBNET2 
aws autoscaling put-scaling-policy --policy-name $ASP_NAME --auto-scaling-group-name \
    $ASG_NAME --policy-type TargetTrackingScaling --target-tracking-configuration file://$SCALEJSON
sleep 3

#Create Load Balancer and attach Auto Scaling Group
export LB_NAME="My-Web-Load-Balancer"
aws elbv2 create-load-balancer --name $LB_NAME --subnets $SUBNET1 $SUBNET2  --security-groups  $LBFROMMYIP
export LB_ARN=$(aws elbv2  describe-load-balancers --name $LB_NAME --query 'LoadBalancers[0].{Arn:LoadBalancerArn}' --output text)
aws elbv2 create-listener  --load-balancer-arn $LB_ARN --protocol $PROTO --port $PORT --default-actions Type=forward,TargetGroupArn=$TG_ARN

