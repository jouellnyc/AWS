#If you've run the create scripts via 'source $script', your shell has all the variable needed to run:
aws ec2 delete-nat-gateway --nat-gateway-id  $NATGW1
aws ec2 delete-nat-gateway --nat-gateway-id  $NATGW2
aws ec2 terminate-instances --instance-ids $INSTANCE1
aws ec2 terminate-instances --instance-ids $INSTANCE2
aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN
aws elbv2 delete-target-group --target-group-arn $TGT_AR
aws ec2 release-address --allocation-id $ELIP1AID
aws ec2 release-address --allocation-id $ELIP2AID
#Then Just Click Delete VPC in the GUI and all the rest will be deleted

