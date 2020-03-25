#!/bin/bash

#### Create an Auto Scaling Launch Configuation ####

source ../shared_vars.txt  >/dev/null 2>&1  || source ./shared_vars.txt 

export USERDATA="../user_data.http.sh"
[ -f $USERDATA ] || { echo "No user data"; exit 55; }

export LC_NAME="Auto-Scaling-Launch-Config-Docker-v2"
export KEY_NAME="vpc-0fb0808e945bfc5f5-key.pem"

aws autoscaling create-launch-configuration --launch-configuration-name $LC_NAME \
--instance-type $TYPE --key-name $KEY_NAME --security-groups $SGROUP1 \
$SGROUP2 $SGROUP3 --iam-instance-profile  $INST_PROF  --user-data file://$USERDATA \
--image-id $AMI && echo "Created AutoScaling Config OK"
