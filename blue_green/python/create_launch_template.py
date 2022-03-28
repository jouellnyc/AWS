#!/usr/bin/env python3

# Refs
# https://stackoverflow.com/questions/39761666/aws-boto3-base64-encoding-error-thrown-when-invoking-client-request-spot-instanc
# https://stackoverflow.com/questions/45482272/typeerror-a-bytes-like-object-is-required-not-str-python-2-to-3
# https://github.com/aws/aws-cli/issues/2453

import sys
import base64

from prod_build_config import aws_profile, inst_profiles, EC2_instance, sec_groups
from aws_cred_objects import AWS_CREDS


def create_launch_template(user_data_file):

    aws = AWS_CREDS(aws_profile)
    ec2_inst= EC2_instance()
    sec_group_ids = [ x['GroupId'] for x in aws.ec2_res.meta.client.describe_security_groups()["SecurityGroups"] ]

    try:
        user_data = open(user_data_file, "r").read().encode("utf-8")
    except OSError as e:
        print('Try another file: ',e)
        sys.exit(1)

    encoded_user_data = base64.b64encode(user_data)
    str_encoded_user_data = encoded_user_data.decode("ascii")

    INSTANCE_PROFILE = inst_profiles[0]
    AMI              = ec2_inst.ami
    LAUNCH_TEMPLATE  = ec2_inst.lt_name
    INSTANCE_TYPE    = ec2_inst.type
    VPCID            = aws.ec2_res.meta.client.describe_vpcs()["Vpcs"][0]['VpcId']
    KEYNAME          = f"{VPCID}-{aws_profile}.pem"

    response = aws.ec2_res.meta.client.create_launch_template(
        LaunchTemplateName= LAUNCH_TEMPLATE,
        LaunchTemplateData={
            "EbsOptimized": False,
            "IamInstanceProfile": {"Name": INSTANCE_PROFILE},
            "ImageId": AMI,
            "InstanceType": INSTANCE_TYPE,
            "KeyName": KEYNAME,
            "Monitoring": {"Enabled": True},
            "SecurityGroupIds": sec_group_ids,
            "UserData": str_encoded_user_data
        }
    )


if __name__ == '__main__':

    user_data_file="../../../DockerStocksWeb/data/user_data.http.AWS.sh"
    create_launch_template(user_data_file)
    print(response)
    
