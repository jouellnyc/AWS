#!/bin/bash

################################################################################
# create_aws_vpc2.sh - https://github.com/jouellnyc/AWS                        #
################################################################################

source ../shared_vars.txt

export VPCID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output text  | grep -ioE "vpc-[A-Za-z0-9]{10,25}")
aws ec2 create-tags --resources $VPCID --tags Key=Name,Value=$VPCLABEL && echo "VPC and Vpc Tags created OK"
aws ec2 create-subnet  --vpc-id $VPCID --cidr-block $SNCIDR1 --availability-zone  $AZ1 && echo "Subnet 1 created OK"
aws ec2 create-subnet  --vpc-id $VPCID --cidr-block $SNCIDR2 --availability-zone  $AZ2 && echo "Subnet 2 created OK"

############No Need to touch below ###########
sleep 2
export SUBNET1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR1" --query 'Subnets[*].{ID:SubnetId}' --output text)
export SUBNET2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR2" --query 'Subnets[*].{ID:SubnetId}' --output text)
aws ec2 create-tags --resources $SUBNET1  --tags Key=Name,Value=subnet-"${AZ1}" && \
aws ec2 create-tags --resources $SUBNET2  --tags Key=Name,Value=subnet-"${AZ2}" && \
aws ec2 modify-subnet-attribute --subnet-id  $SUBNET1 --map-public-ip-on-launch && \
aws ec2 modify-subnet-attribute --subnet-id  $SUBNET2 --map-public-ip-on-launch && \
echo "Subnet Tags and Attributes set OK"

#IGW
export IGWID=$(aws ec2 create-internet-gateway --output text  | awk  '{ print $2 }') && \
aws ec2 attach-internet-gateway --vpc-id $VPCID   --internet-gateway-id $IGWID && \
echo "Internet Gateway Created and attached OK"

#ROUTE TABLE
#aws ec1 create-route-table --vpc-id $VPCID
export RTID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPCID" --query "RouteTables[].RouteTableId[]" --output text)
aws ec2 create-route --route-table-id $RTID  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGWID && \
aws ec2 associate-route-table  --subnet-id $SUBNET1 --route-table-id $RTID && \
aws ec2 associate-route-table  --subnet-id $SUBNET2 --route-table-id $RTID && \
echo "Routes and Route Tables setup OK"

#KEY PAIRS
#Caution!
###KEY PAIRS
export KEYPAIR="${VPCID}-key.pem"
# Caution!
aws ec2 delete-key-pair --key-name $KEYPAIR
[ -f $KEYPAIR ] && rm -f $KEYPAIR
aws ec2 create-key-pair --key-name $KEYPAIR --query 'KeyMaterial' --output text > $KEYPAIR && \
chmod 400 $KEYPAIR && \
echo "Key Pairs created OK"

###SECURITY GROUPS
export LBFROMMYIP=$(aws ec2 create-security-group --group-name LB-FROM-MYIP --description "LBfromMYIP" --vpc-id $VPCID --output text) && \
export LBFROMEC2S=$(aws ec2 create-security-group --group-name LB-FROM-EC2S --description "LBfromEC2s" --vpc-id $VPCID --output text) && \
export EC2FROMLB=$(aws ec2 create-security-group --group-name EC2-FROM-LB --description "EC2fromLB" --vpc-id $VPCID --output text) &&  \
export       SSH=$(aws ec2 create-security-group --group-name SSH --description "SSH" --vpc-id $VPCID --output text) &&  \
echo "Security Groups Created OK"

#Change "--cidr $MYIP/32" to "--cidr 0.0.0.0/0"  to expose to the Internet at large
aws ec2 authorize-security-group-ingress --group-id $LBFROMMYIP --protocol tcp --port 80 --cidr $MYIP/32 && \
aws ec2 authorize-security-group-ingress --group-id $EC2FROMLB  --protocol tcp --port 80 --source-group $LBFROMMYIP && \
aws ec2 authorize-security-group-ingress --group-id $SSH        --protocol tcp --port 22 --cidr $MYIP/32 && \
aws ec2 create-tags --resources $LBFROMMYIP --tags Key=Name,Value="LBFROMMYIP" && \
aws ec2 create-tags --resources $EC2FROMLB  --tags Key=Name,Value="EC2FROMLB"  && \
aws ec2 create-tags --resources $LBFROMEC2S --tags Key=Name,Value="LBFROMEC2S"  && \
aws ec2 create-tags --resources $SSH        --tags Key=Name,Value="SSH"  && \
echo "Security Groups setup and Tags created OK" && \
echo "done!"
