#!/bin/bash  -x 

########################################################
# create_aws_vpc.sh - https://github.com/jouellnyc/AWS #
########################################################

#set -ue

#AVAIL ZONES
export AZ1="us-west-2a"
export AZ2="us-west-2b"

#VPC
export VPCLABEL="PROD-VPC3"
export VPCCIDR="10.0.0.0/16"
export VPCID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output text  | grep -ioE "vpc-[A-Za-z0-9]{10,25}")
aws ec2 create-tags --resources $VPCID --tags Key=Name,Value=$VPCLABEL

#SUBNETS
#Public Subnets
export SNCIDR1="10.0.1.0/24"
export SNCIDR2="10.0.2.0/24"
#Private Subnets
export SNCIDR3="10.0.3.0/24"
export SNCIDR4="10.0.4.0/24"

#MYIP
export MYIP="104.162.77.49"
export NATGWSLEEP="120"

############No Need to touch below ###########
###Subnets 
# Lots of text is returned on create-subnet
# Create Subnets
aws ec2 create-subnet --vpc-id $VPCID --cidr-block $SNCIDR1 --availability-zone  $AZ1
aws ec2 create-subnet --vpc-id $VPCID --cidr-block $SNCIDR2 --availability-zone  $AZ2
aws ec2 create-subnet --vpc-id $VPCID --cidr-block $SNCIDR3 --availability-zone  $AZ1
aws ec2 create-subnet --vpc-id $VPCID --cidr-block $SNCIDR4 --availability-zone  $AZ2

export SUBNET1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR1" --query 'Subnets[*].{ID:SubnetId}' --output text)
export SUBNET2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR2" --query 'Subnets[*].{ID:SubnetId}' --output text)
export SUBNET3=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR3" --query 'Subnets[*].{ID:SubnetId}' --output text)
export SUBNET4=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR4" --query 'Subnets[*].{ID:SubnetId}' --output text)

# Label Subnets
aws ec2 create-tags --resources $SUBNET1  --tags Key=Name,Value=subnet-"Public  Subnet ${AZ1}"
aws ec2 create-tags --resources $SUBNET2  --tags Key=Name,Value=subnet-"Public  Subnet ${AZ2}"
aws ec2 create-tags --resources $SUBNET3  --tags Key=Name,Value=subnet-"Private Subnet ${AZ1}"
aws ec2 create-tags --resources $SUBNET4  --tags Key=Name,Value=subnet-"Private Subnet ${AZ2}"

###Internate Gateway (IGW)
export IGWID=$(aws ec2 create-internet-gateway --output text  | awk  '{ print $2 }')
aws ec2 attach-internet-gateway --vpc-id $VPCID   --internet-gateway-id $IGWID 

###ROUTE TABLES
# Main
#If you have not created a route table yet, there's just the main route tablehe public subnets
export MAINRTID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPCID" --query "RouteTables[].RouteTableId[]" --output text)
#Tag the Main RT
aws ec2 create-tags --resources $MAINRTID --tags Key=Name,Value="MainRouteTable"

# Public
export PUBRTID=$(aws ec2 create-route-table --vpc-id $VPCID | grep -i RouteTableId | awk -F ':' '{ print $2; }' | grep -ioE "rtb-[-0-9a-zA-Z]{4,30}")
aws ec2 create-tags --resources $PUBRTID --tags Key=Name,Value="PublicRouteTable"
aws ec2 create-route --route-table-id $PUBRTID  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGWID 
aws ec2 associate-route-table  --subnet-id $SUBNET1 --route-table-id $PUBRTID
aws ec2 associate-route-table  --subnet-id $SUBNET2 --route-table-id $PUBRTID

# Private
export PVTRTID1=$(aws ec2 create-route-table --vpc-id $VPCID | grep -i RouteTableId | awk -F ':' '{ print $2; }' | grep -ioE "rtb-[-0-9a-zA-Z]{4,30}")
export PVTRTID2=$(aws ec2 create-route-table --vpc-id $VPCID | grep -i RouteTableId | awk -F ':' '{ print $2; }' | grep -ioE "rtb-[-0-9a-zA-Z]{4,30}")
aws ec2 create-tags --resources $PVTRTID1 --tags Key=Name,Value="PrivateRouteTable1"
aws ec2 create-tags --resources $PVTRTID2 --tags Key=Name,Value="PrivateRouteTable2"
aws ec2 associate-route-table  --subnet-id $SUBNET3 --route-table-id $PVTRTID1
aws ec2 associate-route-table  --subnet-id $SUBNET4 --route-table-id $PVTRTID2

###ELastic IPs
# IP Address
export ELIP1=$(aws ec2 allocate-address --output text   | awk {' print $3; '} | grep -ioE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
export ELIP2=$(aws ec2 allocate-address --output text   | awk {' print $3; '} | grep -ioE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
# Allocation IDs
export ELIP1AID=$(aws ec2 describe-addresses --query 'Addresses[?PublicIp==`'$ELIP1'`].{ID:AllocationId}'  --output text)
export ELIP2AID=$(aws ec2 describe-addresses --query 'Addresses[?PublicIp==`'$ELIP2'`].{ID:AllocationId}'  --output text)

###Nat GWs
# Associate with the Public Subnets
export NATGW1=$(aws ec2 create-nat-gateway --subnet-id $SUBNET1 --allocation-id $ELIP1AID | grep -i NatGatewayId | grep -ioE "nat-[0-9A-Za-z]{2,30}")
export NATGW2=$(aws ec2 create-nat-gateway --subnet-id $SUBNET2 --allocation-id $ELIP2AID | grep -i NatGatewayId | grep -ioE "nat-[0-9A-Za-z]{2,30}")
aws ec2 create-tags --resources $NATGW1 --tags Key=Name,Value="NATGW-${AZ1}"
aws ec2 create-tags --resources $NATGW2 --tags Key=Name,Value="NATGW-${AZ2}"

echo "Waiting for NAT GW to start - $NATGWSLEEP seconds"
sleep $NATGWSLEEP #NAT Gw take a bit to spin up

aws ec2 create-route --route-table-id $PVTRTID1  --destination-cidr-block 0.0.0.0/0 --nat-gateway-id  $NATGW1
aws ec2 create-route --route-table-id $PVTRTID2  --destination-cidr-block 0.0.0.0/0 --nat-gateway-id  $NATGW2


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
aws ec2 authorize-security-group-ingress --group-id $LBFROMMYIP --protocol tcp --port 80 --cidr $MYIP/32
#Change "--cidr $MYIP/32" to "--cidr 0.0.0.0/0"  to expose to the Internet at large
aws ec2 authorize-security-group-ingress --group-id $EC2FROMLB  --protocol tcp --port 80 --source-group $LBFROMMYIP
aws ec2 create-tags --resources $LBFROMMYIP --tags Key=Name,Value="LBFROMMYIP"
aws ec2 create-tags --resources $EC2FROMLB  --tags Key=Name,Value="EC2FROMLB"


###EC2 INSTANCES
export TYPE="t2.micro"
export AMI="ami-01bbe152bf19d0289"
export USERDATA="../user_data.http.sh"
[ -f $USERDATA ] || { echo "No user data"; exit 55; } 

aws ec2 run-instances --image-id $AMI  --count 1 --instance-type $TYPE --key-name $KEYPAIR \
        --security-group-ids $EC2FROMLB --subnet-id $SUBNET3 --user-data file://$USERDATA && \
aws ec2 run-instances --image-id $AMI  --count 1 --instance-type $TYPE --key-name $KEYPAIR \
        --security-group-ids $EC2FROMLB --subnet-id $SUBNET4 --user-data file://$USERDATA
