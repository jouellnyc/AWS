#!/bin/bash

### Simple script to up/down the min/max of an ASG ===

set -e

[[ $# -lt 4 ]] && { echo "usage: $0  ASG_NAME LC_NAME MIN MAX"; exit 55;  }

source ../shared_vars.txt >/dev/null 2>&1 || source ./shared_vars.txt

export ASG_NAME=$1
export LC_NAME=$2
export MIN_SERVERS=$3
export MAX_SERVERS=$4

aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME \
--min-size $MIN_SERVERS --max-size $MAX_SERVERS --launch-configuration-name $LC_NAME && \
echo "Appears Successful - Run this:" 
echo "aws autoscaling  describe-scaling-activities  --max-items 1"

#aws autoscaling delete-launch-configuration --launch-configuration-name Auto-Scaling-Launch-Config-Docker-v4
#update_auto_scaling.sh  Auto-Scaling-GRP-GREEN   Auto-Scaling-Launch-Config-Docker-v1 1 1

