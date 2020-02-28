#!/bin/bash

### Simple script to up/down the min/max of an ASG ===

set -e

[[ $# -eq 0 ]] && { echo "usage: $0 MIN MAX"; exit 55;  }

export ASG_NAME="Auto-Scaling-Group"
export MIN_SERVERS=$1
export MAX_SERVERS=$2
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME \
--min-size $MIN_SERVERS --max-size $MAX_SERVERS &&  echo "Appears Successful" \
"run 'aws autoscaling  describe-scaling-activities  --max-items 1' to see progress'"
