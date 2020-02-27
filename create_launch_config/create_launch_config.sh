#!/bin/bash

#### Create an Auto Scaling Launch Configuation ####

export TYPE="t2.micro"
export AMI="ami-01bbe152bf19d0289"
export LC_NAME="Auto-Scaling-Launch-Config-Docker"
export USERDATA="../user_data.http.sh"
#This could be more dynamic...
export SGROUP="sg-028813c0505b2ddfb"

[ -f $USERDATA ] || { echo "No user data"; exit 55; }

aws autoscaling create-launch-configuration --launch-configuration-name $LC_NAME \
--instance-type $TYPE --key-name "PROD-VPC-key.pem" --security-groups $SGROUP \
--user-data file://$USERDATA --image-id $AMI && echo "Created AutoScaling Config OK"
