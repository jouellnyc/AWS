#!/bin/bash

#### Create an Auto Scaling Launch Configuation ####

export LC_NAME="Auto-Scaling-Launch-Config-Docker-v11"

source ../shared_vars.txt  >/dev/null 2>&1  || source ./shared_vars.txt 

export USERDATA="/home/john/gitrepos/shouldipickitup/user_data.http.AWS.sh"
[ -f $USERDATA ] || { echo "No user data"; exit 55; }

aws autoscaling create-launch-configuration --launch-configuration-name $LC_NAME \
--instance-type $TYPE --key-name $KEYPAIR --security-groups $EC2FROMLB \
$LBFROMEC2S $LBFROMMYIP $SSH --iam-instance-profile  $INST_PROF  --user-data file://$USERDATA \
--image-id $AMI && echo "Created AutoScaling Config OK"
