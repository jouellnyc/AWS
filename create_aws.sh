#!/bin/bash

### What: Create a non-default VPC, 2 Subnets, Routes, Internet Gateway
### and tie it all togehther, then expose 2 EC2 instances publicly on the internet
### to save the time in manually provisioning.
### I.E. 'Cloud Formation' AWS quick setup script to test out configs

### Caution: version 1.0 - no real error checking - works well starting a blank VPC
### This is more along the lines of 'vagrant up' to setup a dev staging area.

### TBD: productionalize, adding error checking, maybe use Python - or leave it alone
### TBD: Add some of the user-data below for apache and then auto create an ELB.

set -ue

AZ1=us-west-2a
AZ2=us-west-2b

#VPC
VPCCIDR="10.0.0.0/16"
VPCID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output text  | grep -ioE "vpc-[A-Za-z0-9]{10,25}")
aws ec2 create-tags --resources $VPCID --tags Key=Name,Value=PROD-VPC
export VPCID

#SUBNETS
SNCIDR1="10.0.1.0/24"
SNCIDR2="10.0.2.0/24"
aws ec2 create-subnet --vpc-id $VPCID --cidr-block $SNCIDR1 --availability-zone  $AZ1
aws ec2 create-subnet --vpc-id $VPCID --cidr-block $SNCIDR2 --availability-zone  $AZ1

sleep 2

SUBNET1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR1" --query 'Subnets[*].{ID:SubnetId}' --output text)
SUBNET2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=cidr,Values=$SNCIDR2" --query 'Subnets[*].{ID:SubnetId}' --output text)
aws ec2 create-tags --resources $SUBNET1  --tags Key=Name,Value=subnet-"${AZ1}"
aws ec2 create-tags --resources $SUBNET2  --tags Key=Name,Value=subnet-"${AZ2}"
aws ec2 modify-subnet-attribute --subnet-id  $SUBNET1 --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id  $SUBNET2 --map-public-ip-on-launch

#IGW
IGWID=$(aws ec2 create-internet-gateway --output text  | awk  '{ print $2 }')
aws ec2 attach-internet-gateway --vpc-id $VPCID   --internet-gateway-id $IGWID 

#ROUTE TABLE
#aws ec1 create-route-table --vpc-id $VPCID
RTID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPCID" --query "RouteTables[].RouteTableId[]" --output text)
aws ec2 create-route --route-table-id $RTID  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGWID 
aws ec2 associate-route-table  --subnet-id $SUBNET1 --route-table-id $RTID
aws ec2 associate-route-table  --subnet-id $SUBNET2 --route-table-id $RTID

#KEY PAIRS
#Caution!
KP="MYKEY.pem"
rm -f $KP
aws ec2 create-key-pair --key-name $KP --query 'KeyMaterial' --output text > $KP 
chmod 400 $KP 

#SECURITY GROUPS
SG=$(aws ec2 create-security-group --group-name SSHAccess --description "Security group for SSH access" --vpc-id $VPCID --output text)
aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 22 --cidr 0.0.0.0/0

#RUN EC2
TYPE="t2.micro";AMI="ami-01bbe152bf19d0289"
aws ec2 run-instances --image-id $AMI  --count 1 --instance-type $TYPE --key-name $KP --security-group-ids $SG --subnet-id $SUBNET1
aws ec2 run-instances --image-id $AMI  --count 1 --instance-type $TYPE --key-name $KP --security-group-ids $SG --subnet-id $SUBNET2

###BOXES
#sudo yum update -y
#sudo yum -y install httpd
#sudo service httpd start
#sudo echo "1" > /var/www/html/index.html
#sudo echo "2" > /var/www/html/index.html
