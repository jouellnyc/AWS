""" These are the details to modify to your local environment """

from prod_build_config_defs import (
    Role,
    Sec_Group,
    Auto_Scaling_Bundle,
    Subnet_Bundle,
)

""" AWS Account """
aws_profile = "u2f"

""" VPC Details """
region_name = "us-east-1"

VPC = {
    "vpcname": "MyVPC3",
    "vpc_cidr": "10.0.0.0/16",
    "mycidr": "104.162.78.13/32",
    "all": "0.0.0.0/0",
}

""" WWW Site Name """
web_site_name = "www.justgrowthrates.com"

""" Security Groups Details """
sec_groups = [
    Sec_Group(port=22, name="SSH", description="SSH", proto="tcp", myip=VPC["mycidr"]),
    Sec_Group(
        port=443, name="HTTPS", description="HTTPS", proto="tcp", myip=VPC["mycidr"]
    ),
    Sec_Group(
        port=80, name="HTTP", description="HTTP", proto="tcp", myip=VPC["mycidr"]
    ),
    Sec_Group(port=80, name="LB2EC2", description="LB2EC2", proto="tcp", myip="HTTP"),
    Sec_Group(
        port=9001, name="FlyWheel", description="FlyWheel", proto="tcp", myip=VPC["all"]
    ),
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
        asg_max_srv=1,
        tg_name="Target-GRP-Auto-Scale-GREEN",
        tg_port=80,
        tg_proto="HTTP",
        asg_cpu_scale_out=70.0,
    ),
    Auto_Scaling_Bundle(
        asg_name="Auto-Scaling-GRP-BLUE",
        asg_min_srv=0,
        asg_max_srv=1,
        tg_name="Target-GRP-Auto-Scale-BLUE",
        tg_port=80,
        tg_proto="HTTP",
        asg_cpu_scale_out=70.0,
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
log_groups = ["nginx", "flask", "mongodb", "crawler", "flywheel"]


""" EC2 Instance Details """


class EC2_instance:
    def __init__(self):
        self.type = "t2.micro"
        self.ami = "ami-0fc61db8544a617ed"
        self.lt_name = "Devops-Auto-Scaling-Launch-Template-Base"


""" Load Balancer Details """


class LoadBalancer:
    def __init__(self):
        self.name = "My-Web-Load-Balancer"
        self.targets = "My-Web-Targets"
        self.SslPolicy = "ELBSecurityPolicy-2016-08"
        self.port = 80
        self.proto = "HTTP"
        self.redirect_to_port = 443
        self.redirect_to_proto = "HTTPS"
        self.redirect_status_code = "HTTP_301"
