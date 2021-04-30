#!/usr/bin/env python3


from prod_build_config import aws_profile
from aws_cred_objects import AWS_CREDS

aws = AWS_CREDS(aws_profile)

def launch(name, version):
    
        aws.ec2_res.create_instances(
        LaunchTemplate={"LaunchTemplateName": name, "Version": str(version) },
        MinCount=1,
        MaxCount=1,
        SubnetId="subnet-0b044a7ae98bb2b00",
    )
    
    
if __name__ == '__main__':
    
    launch("Flywheel",4)