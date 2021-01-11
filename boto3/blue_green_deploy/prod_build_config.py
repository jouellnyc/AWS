""" These are the details to modify to your local environment """

from prod_build_config_defs import (
    Role,
    Sec_Group,
    Auto_Scaling_Bundle,
    Subnet_Bundle,
)

""" VPC Details """
region_name = "us-east-1"

VPC = {
    "vpcname": "MyVPC3",
    "vpc_cidr": "10.0.0.0/16",
    "mycidr": "104.162.67.217/32",
}


""" Security Groups Details """
sec_groups = [
    Sec_Group(port=22, name="SSH", description="SSH", proto="tcp", myip=VPC["mycidr"]),
    Sec_Group(
        port=80, name="HTTP", description="HTTP", proto="tcp", myip=VPC["mycidr"]
    ),
    Sec_Group(port=80, name="LB2EC2", description="LB2EC2", proto="tcp", myip="HTTP"),
]


""" Policies Managed my AWS """
aws_policies = [
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
]

aws_policies_names = ["CloudWatchFullAccess", "SecretsManagerReadWrite"]


""" App Roles Details """
roles = [Role(name="EC2AppRole", file="../../IAM/iam.trustpolicyforec2.json")]


""" App Scaling Group Details """
auto_scaling_bundles = [
    Auto_Scaling_Bundle(
        asg_name="Auto-Scaling-GRP-GREEN",
        asg_min_srv=1,
        asg_max_srv=2,
        tg_name="Target-GRP-Auto-Scale-GREEN",
        tg_port=80,
        tg_proto="HTTP",
    ),
    Auto_Scaling_Bundle(
        asg_name="Auto-Scaling-GRP-BLUE",
        asg_min_srv=1,
        asg_max_srv=2,
        tg_name="Target-GRP-Auto-Scale-BLUE",
        tg_port=80,
        tg_proto="HTTP",
    ),
]


""" Subnet Details """
subnet_bundles = [
    Subnet_Bundle(subnet_name="SubNet1", az=f"{region_name}a", cidr="10.0.1.0/24"),
    Subnet_Bundle(subnet_name="SubNet2", az=f"{region_name}b", cidr="10.0.2.0/24"),
]


""" Instance Profile Details """
inst_profiles = [
    "AWS_EC2_INSTANCE_PROFILE_ROLE",
]


""" Log Group Details """
log_groups = ["nginx", "flask", "mongodb"]


""" EC2 Instance Details """


class EC2_instance:
    def __init__(self):
        self.type = "t2.micro"
        self.ami = "ami-0fc61db8544a617ed"
        self.lc_name = "Auto-Scaling-Launch-Config-Docker-v1"


""" Load Balancer Details """


class LoadBalancer:
    def __init__(self):
        self.name = "My-Web-Load-Balancer2"
        self.targets = "My-Web-Targets"
        self.port = 80
        self.proto = "HTTP"
