#!/usr/bin/env python3

""" This is the primary build VPC script """

import sys
import time
import json
import base64
import random
import pprint

from prod_build_config import (
    VPC,
    EC2_instance,
    inst_profiles,
    aws_policies,
    roles,
    log_groups,
    sec_groups,
    auto_scaling_bundles,
    subnet_bundles,
    LoadBalancer,
    aws_profile,
    web_site_name
)

from aws_cred_objects import AWS_CREDS
from aws_cert_mgr import get_cert_arn
import update_dns_cloud_flare


""" Pull in the Precise userdata for each instances build """
user_data_file = "../../../DockerStocksWeb/data/user_data.http.AWS.sh"
try:
    user_data = open(user_data_file, "r").read().encode("utf-8")
    encoded_user_data = base64.b64encode(user_data)
    userdata = encoded_user_data.decode("ascii")
except OSError as e:
    print('Try another file: ',e)
    sys.exit(1)

class BUILD:
    def __init__(self, aws_creds, VPC):

        """ Things we imported """
        self.VPC = VPC
        self.vpc_cidr = self.VPC["vpc_cidr"]
        self.vpcname = self.VPC["vpcname"]
        self.ec2_res = aws_creds.ec2_res
        self.ec2_client = aws_creds.ec2_res.meta.client
        self.iam_client = aws_creds.iam_client
        self.logs_client = aws_creds.logs_client
        self.as_client = aws_creds.as_client
        self.elbv2_client = aws_creds.elbv2_client
        self.profile_name = aws_creds.profile_name
        self.ec2_inst = EC2_instance()
        self.LoadBalancer = LoadBalancer()

        """ Things we will set via boto3 """
        self.sec_groups = {}
        self.subnets = []
        self.target_groups = {}
        self.auto_scaling_groups = {}
        self.load_balancer = ""
        self.listener = ""
        self.launch_config = ""

    def __str__(self):
        return f"""VPC NAME: {self.vpcname}
VPC ID: {self.vpcid}

SG: {self.sec_groups}

SN: {self.subnets}

TG: {self.target_groups}

AS: {self.auto_scaling_groups}

LB: {self.load_balancer}

LS: {self.listener}"""

    def my_create_vpc(self, tagged=True):
        """ Create VPC """
        try:
            self.tagged = tagged
            self.vpc = self.ec2_res.create_vpc(CidrBlock=str(self.vpc_cidr))
            self.vpc.wait_until_available()
            self.vpcid = self.vpc.vpc_id
            self.message = f"VPC {self.vpcname}, {self.vpcid} was created "
            if self.tagged:
                self.vpctag = self.ec2_res.create_tags(
                    Resources=[self.vpcid],
                    Tags=[{"Key": "Name", "Value": self.vpcname},],
                )

        except Exception:
            raise
        else:
            if self.tagged:
                return self.message + "and tagged OK"
            else:
                return self.message + "OK"

    def my_create_subnet(self, subnet_bundle):
        """ Create Subnets in precise Availability Zones """
        try:

            subnet = self.ec2_res.create_subnet(
                AvailabilityZone=subnet_bundle.az,
                CidrBlock=subnet_bundle.cidr,
                VpcId=self.vpcid,
            )

            time.sleep(2)

            self.ec2_client.modify_subnet_attribute(
                SubnetId=subnet.id, MapPublicIpOnLaunch={"Value": True}
            )

            self.ec2_res.create_tags(
                Resources=[subnet.id],
                Tags=[{"Key": "Name", "Value": subnet_bundle.subnet_name}],
            )

            """  Add All subnets to the object """
            self.subnets.append(subnet)

        except Exception as e:
            print("SN: Subnet Problem: ", e)
        else:
            print(f"SN: {subnet_bundle.subnet_name}  ({subnet.id}) created OK")

    def my_create_igw(self):
        """ Create the Internet Gateway """
        try:
            self.igw = self.ec2_res.create_internet_gateway()
            self.igw.attach_to_vpc(VpcId=self.vpcid)
        except Exception as e:
            print("IGW: create failed ", e)
        else:
            print("IGW: created and attached OK")

    def my_create_routes(self):
        """ Create the Routes """
        try:

            for x in self.ec2_res.route_tables.filter(
                Filters=[{"Name": "vpc-id", "Values": [self.vpcid]}]
            ):
                self.main_rt_id = x.id
                self.main_rt = x

            self.client = self.ec2_res.meta.client

            self.client.create_route(
                DestinationCidrBlock="0.0.0.0/0",
                GatewayId=self.igw.id,
                RouteTableId=self.main_rt_id,
            )

            for subnet in self.subnets:

                self.client.associate_route_table(
                    RouteTableId=self.main_rt_id, SubnetId=subnet.id
                )

        except Exception as e:
            print("RT: Routes create failed ", e)
        else:
            print("RT: Routes created and attached to Route Table OK")

    def my_create_keypair(self):
        """ Create Keypairs """

        try:
            self.key_pair = self.ec2_res.create_key_pair(
                KeyName=f"{self.vpcid}-{self.profile_name}.pem"
            )

            with open(f"{self.vpcid}-{self.profile_name}.pem", "w") as file:
                file.write(self.key_pair.key_material)

        except Exception as e:
            print("KP: KeyPair Create Failed ", e)
        else:
            print("KP: KeyPair Created and Saved OK")

    def my_create_security_groups(self, sec_group):

        try:

            """ Create Group """
            response = self.ec2_res.create_security_group(
                Description=sec_group.description,
                GroupName=sec_group.name,
                VpcId=self.vpcid,
            )

            self.sec_groups[sec_group.name] = response

            if sec_group.name != "LB2EC2":

                """ We create Groups differently  as we set a Security Group """
                """ OR We set a CIDR for src/dest filters                    """

                """ Authorize Group """
                self.ec2_res.meta.client.authorize_security_group_ingress(
                    GroupId=self.sec_groups[sec_group.name].id,
                    IpPermissions=[
                        {
                            "FromPort": sec_group.port,
                            "IpProtocol": sec_group.proto,
                            "IpRanges": [
                                {
                                    "CidrIp": sec_group.myip,
                                    "Description": sec_group.description,
                                },
                            ],
                            "ToPort": sec_group.port,
                        },
                    ],
                )

            else:
                # "LB2EC2"
                self.ec2_res.meta.client.authorize_security_group_ingress(
                    GroupId=self.sec_groups[sec_group.name].id,
                    IpPermissions=[
                        {
                            "FromPort": sec_group.port,
                            "IpProtocol": sec_group.proto,
                            "ToPort": sec_group.port,
                            "UserIdGroupPairs": [
                                {
                                    "Description": "HTTP access from other instances",
                                    "GroupId": self.sec_groups["HTTP"].id,
                                },
                            ],
                        },
                    ],
                )

            """ Tag Group """
            time.sleep(5)
            self.ec2_res.meta.client.create_tags(
                Resources=[self.sec_groups[sec_group.name].id,],
                Tags=[{"Key": "Name", "Value": sec_group.name,},],
            )

        except Exception as e:

            print("Security Group Issue: ", e)

        else:
            print(
                f'SG: "{sec_group.name}" ({response.id}) Created, ACLs set and Tagged OK'
            )

    def my_create_instance_profile(self, inst_prof_name):
        """ Create Inst Prof """

        try:
            self.inst_prof_name = inst_prof_name
            self.iam_client.create_instance_profile(InstanceProfileName=inst_prof_name)
        except self.iam_client.exceptions.EntityAlreadyExistsException:
            print(f"IP: Instance Profle {inst_prof_name} Already Exists -- skipping")
            pass
        except Exception as e:
            print("IP: Inst prof problem ", e)
        else:
            time.sleep(15)
            print(f"IP: Instance Profle {inst_prof_name} Created OK")

    def my_create_app_role(self, app_role_name, app_role_file):
        """ Create App Role """

        self.app_role_name = app_role_name

        try:
            with open(app_role_file) as ph:
                string_policy = json.load(ph)
                json_policy = json.dumps(string_policy)
            self.iam_client.create_role(
                AssumeRolePolicyDocument=json_policy, Path="/", RoleName=role_name,
            )
        except self.iam_client.exceptions.EntityAlreadyExistsException:
            print(f"AR: App role {app_role_name} Already Exists -- skipping")
            pass
        except Exception as e:
            print("AR: App Role problem - Still need to insert to Inst Prof", e)
            pass
        else:
            print(f"AR: App role {app_role_name} Created OK")

        try:
            self.iam_client.add_role_to_instance_profile(
                InstanceProfileName=inst_prof_name, RoleName=app_role_name,
            )
        except self.iam_client.exceptions.LimitExceededException:
            print(f"AR: {inst_prof_name} already has a Role --  Skipping")
            pass
        except Exception as e:
            print(
                "AR: Problem adding role {app_role_name} to instance profile {inst_prof_name} ",
                e,
            )
        else:
            time.sleep(15)
            print(
                f"AR: Added role {app_role_name} to instance profile {inst_prof_name}  OK"
            )

    def my_create_policy(self, policy_name, policy_file, policy_desc):
        """ Create Policy"""
        try:

            with open(policy_file) as ph:
                string_policy = json.load(ph)
                json_policy = json.dumps(string_policy)
            self.iam_client.create_policy(
                PolicyName=policy_name,
                PolicyDocument=json_policy,
                Path="/",
                Description=policy_desc,
            )

        except self.iam_client.exceptions.EntityAlreadyExistsException:
            print(f"PL: Policy {policy_name} Already exists -- skipping")
            pass
        except Exception as e:
            print("PL: Policy Creation problem ", e)
        else:
            print(f"PL: Policy {policy_name} Created OK")

        try:
            """    This is an update OR new insertion         """
            """    No Error if the policy already is inserted  """
            self.iam_client.put_role_policy(
                PolicyDocument=json_policy,
                PolicyName=policy_name,
                RoleName=self.app_role_name,
            )
        except Exception as e:
            print("PL: Policy Insertion problem ", e)
        else:
            print(f"PL: Policy {policy_name} inserted to {self.app_role_name} OK ")

    def my_attach_policy(self, aws_policy_arn):
        """ Attach the policy """
        try:
            role = "EC2AppRole"
            self.iam_client.attach_role_policy(RoleName=role, PolicyArn=aws_policy_arn)
        except Exception as e:
            print("PL: Policy Attach problem ", e)
        else:
            print(f"PL: Policy {aws_policy_arn} Attached to {role} OK")

    def my_create_log_groups(self, log_group_name):
        """ Create the Log Groups """
        try:
            self.logs_client.create_log_group(logGroupName=log_group_name)
        except self.logs_client.exceptions.ResourceAlreadyExistsException:
            print(f"LG: Log Group {log_group_name} Already Exists -- skipping")
            pass
        except Exception as e:
            print("LG: Log Group problem ", e)
        else:
            print(f"LG: Log group {log_group_name} Created OK")

    def my_create_launch_template(self):
        """ Create the Launch Template """
        try:
            self.ec2_client.create_launch_template(
                 LaunchTemplateName = self.ec2_inst.lt_name,

                 LaunchTemplateData = {
                     "EbsOptimized": False,
                     "IamInstanceProfile": {"Name": self.inst_prof_name},
                     "ImageId": self.ec2_inst.ami,
                     "InstanceType": self.ec2_inst.type,
                     "KeyName": f"{self.vpcid}-{self.profile_name}.pem",
                     "Monitoring": {"Enabled": True},
                     "SecurityGroupIds": [ x.id for x in self.sec_groups.values() ],
                     "UserData": userdata
                  }
             )
        except Exception as e:
            print("LT: Launch Template problem: ", e)
        else:
            time.sleep(15)
            print(f"LT: Launch Template  {self.ec2_inst.lt_name} Created OK")

    def my_create_t_a_p_group(self, auto_scaling_bundle, subnet_bundles):
        """ Create the Target Groups, AS Groups and put the Policy in """
        try:

            tg_name = auto_scaling_bundle.tg_name
            as_name = auto_scaling_bundle.asg_name

            self.target_groups[tg_name] = self.elbv2_client.create_target_group(
                Name=tg_name,
                Port=auto_scaling_bundle.tg_port,
                Protocol=auto_scaling_bundle.tg_proto,
                VpcId=self.vpcid,
            )

            TargetGroupARN = self.target_groups[tg_name]["TargetGroups"][0][
                "TargetGroupArn"
            ]

            self.auto_scaling_groups[
                as_name
            ] = self.as_client.create_auto_scaling_group(
                AutoScalingGroupName=as_name,
                LaunchTemplate={
                        'LaunchTemplateName': self.ec2_inst.lt_name,
                        'Version': str(1)
                 },
                MaxSize=auto_scaling_bundle.asg_max_srv,
                MinSize=auto_scaling_bundle.asg_min_srv,
                VPCZoneIdentifier=",".join([x.id for x in self.subnets]),
                TargetGroupARNs=[TargetGroupARN],
            )

            self.as_client.put_scaling_policy(
                AdjustmentType="ChangeInCapacity",
                AutoScalingGroupName=auto_scaling_bundle.asg_name,
                PolicyName="cpu-alert",
                PolicyType="TargetTrackingScaling",
                TargetTrackingConfiguration={
                    "TargetValue": 70.0,
                    "PredefinedMetricSpecification": {
                        "PredefinedMetricType": "ASGAverageCPUUtilization"
                    },
                },
            )

        except self.elbv2_client.exceptions.DuplicateTargetGroupNameException:
            print("TG: Target Group Exists Already -- skipping")
            pass
        except Exception:
            raise
        else:
            time.sleep(5)
            print(f"TG: Target {tg_name} and Auto Scaling {as_name} groups created OK")

    def my_create_load_balancer(self, LoadBalancer, randomAS=False):
        """ Create The Load Balancer """

        try:

            LBName = f"{self.LoadBalancer.name}-{self.vpcname}"

            if randomAS:
                """ We randomly choose the Target / ASGroup """
                FirstTg_Group = random.choice([x for x in self.target_groups.keys()])
            else:
                FirstTg_Group = "Target-GRP-Auto-Scale-GREEN"

            print(f"LB: {FirstTg_Group} chosen for Target Group")

            self.load_balancer = self.elbv2_client.create_load_balancer(
                Name=LBName,
                Subnets=[x.id for x in self.subnets],
                SecurityGroups=[x.id for x in self.sec_groups.values()],
            )

            print(f"LB: {LBName} Created  OK")

            self.LB_ARN = self.load_balancer["LoadBalancers"][0]["LoadBalancerArn"]
            Tg_Grn = self.target_groups[FirstTg_Group]["TargetGroups"][0][
                "TargetGroupArn"
            ]

            self.CertARN = get_cert_arn()
            self.listener = self.elbv2_client.create_listener(
                DefaultActions=[{"TargetGroupArn": Tg_Grn, "Type": "forward",},],
                LoadBalancerArn=self.LB_ARN,
                Port=self.LoadBalancer.port,
                Protocol=self.LoadBalancer.proto,
                SslPolicy=self.LoadBalancer.SslPolicy,
                Certificates=[{"CertificateArn": self.CertARN,},],
            )
            self.listener = self.elbv2_client.create_listener(
                LoadBalancerArn=self.LB_ARN,
                Port=self.LoadBalancer.port,
                Protocol=self.LoadBalancer.proto,
                DefaultActions=[
                    {
                        "Type": "redirect",
                        "Order": 1,
                        "RedirectConfig": {
                            "Port": self.redirect_port,
                            "Protocol": self.redirect_proto,
                            "Host": web_site_name,
                            "Path": "/#{path}",
                            "Query": "#{query}",
                            "StatusCode": self.redirect_status_code
                        },
                    }
                ],
            )
        except Exception as e:
            print("LB: LB problem: ", e)
        else:
            print(f"LB: Target Group {FirstTg_Group} attached to {LBName} OK")


if __name__ == "__main__":

    aws_creds = AWS_CREDS(aws_profile)
    prod_vpc = BUILD(aws_creds, VPC)
    print("Profile: ", aws_profile)

    print(prod_vpc.my_create_vpc(tagged=True))
    for subnet_bundle in subnet_bundles:
        prod_vpc.my_create_subnet(subnet_bundle)
    prod_vpc.my_create_igw()
    prod_vpc.my_create_routes()
    prod_vpc.my_create_keypair()
    for sec_group in sec_groups:
        prod_vpc.my_create_security_groups(sec_group)
    for inst_prof_name in inst_profiles:
        prod_vpc.my_create_instance_profile(inst_prof_name)
    for role_name, role_file in roles:
        prod_vpc.my_create_app_role(role_name, role_file)
    for aws_policy_arn in aws_policies:
        prod_vpc.my_attach_policy(aws_policy_arn)
    for log_group_name in log_groups:
        prod_vpc.my_create_log_groups(log_group_name)
    prod_vpc.my_create_launch_template()
    for auto_scaling_bundle in auto_scaling_bundles:
        prod_vpc.my_create_t_a_p_group(auto_scaling_bundle, subnet_bundles)
    prod_vpc.my_create_load_balancer(LoadBalancer)
    print("LB: ", end='')
    pprint.pprint(update_dns_cloud_flare.update_one_dns_record(update_dns_cloud_flare.WWW,'CNAME',prod_vpc.load_balancer['LoadBalancers'][0]['DNSName']))
