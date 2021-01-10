#!/usr/bin/env python3

import boto3.session
from prod_build_config import region_name
        

class AWS_CREDS:

    def __init__(self, profile_name):
        
        self.profile_name = profile_name
        
        """ Create ec2 resource from the session object """
        self.my_session = boto3.session.Session(profile_name=profile_name, region_name=region_name)
        
        self.ec2_res = self.my_session.resource("ec2", region_name)
        
        
        """ Create other clients manually """
        self.elbv2_client = boto3.session.Session(profile_name=profile_name).client(
            "elbv2", region_name
        )
        
        self.as_client = boto3.session.Session(profile_name=profile_name).client(
            "autoscaling", region_name
        )
        
        self.iam_client = boto3.session.Session(profile_name=profile_name).client("iam", region_name)
        
        
        self.logs_client = boto3.session.Session(profile_name=profile_name).client(
            "logs", region_name
        )
