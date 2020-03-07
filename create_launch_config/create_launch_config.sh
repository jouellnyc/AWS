#!/bin/bash

#### Create an Auto Scaling Launch Configuation ####

source ../shared_vars.txt  >/dev/null 2>&1  || source ./shared_vars.txt 

export TYPE="t2.micro"
export AMI="ami-01bbe152bf19d0289"
export USERDATA="../user_data.http.sh"

[ -f $USERDATA ] || { echo "No user data"; exit 55; }

aws autoscaling create-launch-configuration --launch-configuration-name $LC_NAME \
--instance-type $TYPE --key-name "PROD-VPC-key.pem" --security-groups $SGROUP1 \
$SGROUP2 $SGROUP3 --iam-instance-profile  $INST_PROF  --user-data file://$USERDATA \
--image-id $AMI && echo "Created AutoScaling Config OK"
