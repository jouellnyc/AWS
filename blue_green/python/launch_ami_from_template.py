#!/usr/bin/env python3


import random

from prod_build_config import aws_profile, inst_profiles 
from aws_cred_objects import AWS_CREDS


def launch(name, version, subnet_id, max=1, min=1):

    print(aws.ec2_res.create_instances(
        LaunchTemplate={"LaunchTemplateName": name, "Version": str(version) },
        SubnetId = subnet_id,
        MinCount = min,
        MaxCount = max,
    ))
    

if __name__ == '__main__':
    
    aws = AWS_CREDS(aws_profile)
    subnet_id = random.choice(list(aws.ec2_res.subnets.all())).id
    #launch("Auto-Scaling-Launch-Template-Base", 1, subnet_id)
    #launch("HTTP", 1, subnet_id)
    launch("FlyWheel", 1, subnet_id)
    launch("Crawler", 1, subnet_id)
    #launch("Crawler", 1, subnet_id,min=50,max=50)
    #launch("Crawler", 1, subnet_id,min=25,max=35)
    #Add instance ip to mongodb
    #Add flywheel ip to instance
