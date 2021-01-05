profile_name = "dev"

import boto3.session
from prod_build_config import region_name

""" Create ec2 resource from the session object """
my_session = boto3.session.Session(profile_name=profile_name, region_name=region_name)
ec2_res = my_session.resource("ec2", region_name)


""" Create other clients manually """
elbv2_client = boto3.session.Session(profile_name=profile_name).client(
    "elbv2", region_name
)

as_client = boto3.session.Session(profile_name=profile_name).client(
    "autoscaling", region_name
)

iam_client = boto3.session.Session(profile_name=profile_name).client("iam", region_name)


logs_client = boto3.session.Session(profile_name=profile_name).client(
    "logs", region_name
)
