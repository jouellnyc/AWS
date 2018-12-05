#!/bin/bash 

########################################################
# create_aws_vpc.sh - https://github.com/jouellnyc/AWS #
########################################################

set -ue

#AVAIL ZONES
export AZ1=us-west-2a
export AZ2=us-west-2b

#VPC
export VPCLABEL="PROD-VPC5"
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
export KEYPAIR="${VPCLABEL}-key.pem"
[ -f $KEYPAIR ] && rm -f $KEYPAIR
aws ec2 create-key-pair --key-name $KEYPAIR --query 'KeyMaterial' --output text > $KEYPAIR
chmod 400 $KEYPAIR

#SECURITY GROUPS
export  SSH_SG=$(aws ec2 create-security-group --group-name SSHAccess  --description "Security group for SSH access" --vpc-id $VPCID --output text)
export HTTP_SG=$(aws ec2 create-security-group --group-name HTTPAccess --description "Security group for HTTP access" --vpc-id $VPCID --output text)
aws ec2 authorize-security-group-ingress --group-id $SSH_SG  --protocol tcp --port 22 --cidr $MYIP/32
aws ec2 authorize-security-group-ingress --group-id $HTTP_SG --protocol tcp --port 80 --cidr $MYIP/32

#EC2 INSTANCES
export TYPE="t2.micro"
export AMI="ami-01bbe152bf19d0289"
export USERDATA="../user_data.http.sh"
[ -f $USERDATA ] || { echo "No user data"; exit 55; } 

aws ec2 run-instances --image-id $AMI  --count 1 --instance-type $TYPE --key-name $KEYPAIR --security-group-ids $SSH_SG $HTTP_SG --subnet-id $SUBNET1 --user-data file://$USERDATA && \
aws ec2 run-instances --image-id $AMI  --count 1 --instance-type $TYPE --key-name $KEYPAIR --security-group-ids $SSH_SG $HTTP_SG --subnet-id $SUBNET2 --user-data file://$USERDATA && \
while read -r IP1 IP2; do 
	echo "== Wait 2 mintutes and then check: ==";
       	echo "http://$IP1/"
       	echo "http://$IP2/"
	echo ssh -i $KEYPAIR ec2-user@"${IP1}"
	echo ssh -i $KEYPAIR ec2-user@"${IP2}"
done < <(aws ec2 describe-instances  --filters "Name=vpc-id,Values=$VPCID"  --query 'Reservations[*].Instances[0].PublicIpAddress' --output text)
