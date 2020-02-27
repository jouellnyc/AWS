#!/bin/bash

#### Create an Auto Scaling Launch Configuation ####

export LC_NAME="Auto-Scaling-Launch-Config-Docker-v3"
export TYPE="t2.micro"
export AMI="ami-01bbe152bf19d0289"
export USERDATA="../user_data.http.sh"
#This could be more dynamic...
#LB-FROM-EC2S, SSH, and EC2-FROM-LB 
export SGROUP1="sg-00b4e2e5337079a81"
export SGROUP2="sg-028813c0505b2ddfb"
export SGROUP3="sg-0842bd4fffc901c60"

[ -f $USERDATA ] || { echo "No user data"; exit 55; }

aws autoscaling create-launch-configuration --launch-configuration-name $LC_NAME \
--instance-type $TYPE --key-name "PROD-VPC-key.pem" --security-groups $SGROUP1 \
$SGROUP2 $SGROUP2 --user-data file://$USERDATA --image-id $AMI && echo "Created AutoScaling Config OK"
