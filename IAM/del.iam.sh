#!/bin/bash

source ../shared_vars.txt
aws iam remove-role-from-instance-profile --instance-profile-name $INST_PROF  --role-name $CW_ROLE 
aws iam delete-instance-profile --instance-profile-name $INST_PROF 
aws iam delete-role --role-name $CW_ROLE 
POLICY=$(aws iam list-policies --scope Local --output json  | grep -A 2 PolicyName | grep Arn | cut -d ":" -f2- | cut -d \" -f2)
aws iam delete-policy --policy-arn $POLICY

