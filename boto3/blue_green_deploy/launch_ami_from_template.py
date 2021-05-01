#!/usr/bin/env python3


from prod_build_config import aws_profile
from aws_cred_objects import AWS_CREDS

aws = AWS_CREDS(aws_profile)

def launch(name, version, max=1, min=1):
    
        aws.ec2_res.create_instances(
        LaunchTemplate={"LaunchTemplateName": name, "Version": str(version) },
        MinCount=min,
        MaxCount=max,
        SubnetId="subnet-0b044a7ae98bb2b00",
    )
    
    
if __name__ == '__main__':
    
    
    launch("Flywheel", 6)
    launch("Crawler", 1)
    
    