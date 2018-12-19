#!/bin/bash 

################################################################################
# create_ec2s_elbv2_vpc2a.sh - https://github.com/jouellnyc/AWS 
################################################################################

####EC2 INSTANCES
aws ec2 run-instances --image-id $AMI --count 1 --instance-type $TYPE --key-name \
    $KEYPAIR --security-group-ids $EC2FROMLB --subnet-id $SUBNET1 --user-data    \
    file://$USERDATA
aws ec2 run-instances --image-id $AMI --count 1 --instance-type $TYPE --key-name \
    $KEYPAIR --security-group-ids $EC2FROMLB --subnet-id $SUBNET2 --user-data    \
    file://$USERDATA 
