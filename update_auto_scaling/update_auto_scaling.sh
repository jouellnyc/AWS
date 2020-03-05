#!/bin/bash

### Simple script to up/down the min/max of an ASG ===

set -e

[[ $# -eq 0 ]] && { echo "usage: $0 MIN MAX"; exit 55;  }

export ASG_NAME=${1:-"Auto-Scaling-Group"}
#Auto-Scaling-Group-BLUE
#Auto-Scaling-Group-GREEN

export MIN_SERVERS=$1
export MAX_SERVERS=$2
source ../shared_vars.txt >/dev/null 2>&1 || source ./shared_vars.txt

aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME \
--min-size $MIN_SERVERS --max-size $MAX_SERVERS --launch-configuration-name $LC_NAME && \
echo "Appears Successful - Run this:" 
echo "aws autoscaling  describe-scaling-activities  --max-items 1"
