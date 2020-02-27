#!/bin/bash

### Simple script to up/down the min/max of an ASG ===

export ASG_NAME="Auto-Scaling-Group"
export MIN_SERVERS=NUM1
export MAX_SERVERS=NUM2
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME   --min-size $MIN_SERVERS --max-size $MAX_SERVERS
