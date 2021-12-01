#!/usr/bin/env python3


from prod_build_config import (
    EC2_instance,
    sec_groups,
    inst_profiles,
    aws_profile
)



from aws_cred_objects import AWS_CREDS
aws = AWS_CREDS(aws_profile)

inst = EC2_instance()
sec_grps= sec_groups()

print([x.name for x in sec_grps])

import sys
sys.exit(1)
aws.ec2_res.create_instances(ImageId=inst.ami,
                     InstanceType=inst.type,
                     MinCount=1, MaxCount=1,
                     SecurityGroupIds=[x.name for x in sec_grps],
                     KeyName='vpc-0740504a74ea5eac9-stocks.pem',
                     IamInstanceProfile={
                         'Name': inst_profiles[0]
                     })