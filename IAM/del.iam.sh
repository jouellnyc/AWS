#!/bin/bash

source ../shared_vars.txt
aws iam remove-role-from-instance-profile --instance-profile-name $INST_PROF  --role-name $CW_ROLE 
aws iam delete-instance-profile --instance-profile-name $INST_PROF 
aws iam delete-role --role-name $CW_ROLE 

POLICY1=$(aws iam list-policies --scope Local --output json  | grep  $AS_POLICY | grep Arn | cut -d \"  -f4)
POLICY2=$(aws iam list-policies --scope Local --output json  | grep  $CW_POLICY | grep Arn | cut -d \"  -f4)
aws iam delete-policy --policy-arn $POLICY1
aws iam delete-policy --policy-arn $POLICY2

export WEB_SRV="nginx"
export WEB_APP="flask"
export DB="mongodb"

for log_group in $WEB_SRV $WEB_APP $DB; do 
    aws logs delete-log-group --log-group-name $log_group
done

