""" These are the details to modify to your local environment """

from prod_build_config_defs import (
    Policy,
    Role,
    EC2_Instance,
    Sec_Group,
    Auto_Scaling_Bundle,
    Subnet_Bundle,
)

region_name = "us-east-1"


VPC = {
    "vpcname": "MyVPC3",
    "vpc_cidr": "10.0.0.0/16",
    "mycidr": "104.162.67.217/32",
}


sec_groups = [
    Sec_Group(port=22, name="SSH", description="SSH", proto="tcp", myip=VPC["mycidr"]),
    Sec_Group(
        port=80, name="HTTP", description="HTTP", proto="tcp", myip=VPC["mycidr"]
    ),
    Sec_Group(port=80, name="LB2EC2", description="LB2EC2", proto="tcp", myip="HTTP"),
]

aws_policies = [
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
]

aws_policies_names = ["CloudWatchFullAccess", "SecretsManagerReadWrite"]

policies = [
    Policy(
        name="CloudWatchSendPolicy",
        desc="CloudWatchSendPolicy",
        file="../../IAM/iam.cloudwatch.json",
    ),
    Policy(
        name="AwsSecretsPolicy",
        desc="AwsSecretsPolicy",
        file="../../IAM/iam.aws_secrets_mgr.json",
    ),
]


roles = [Role(name="EC2AppRole", file="../../IAM/iam.trustpolicyforec2.json")]


ec2_instances = [
    EC2_Instance(
        type="t2.micro",
        ami="ami-0fc61db8544a617ed",
        userdata="~/gitrepos/jouell/shouldipickitup/user_data.http.AWS.sh",
        cpu_scaling_file="cpu.json",
    )
]


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

subnet_bundles = [
    Subnet_Bundle(subnet_name="SubNet1", az=f"{region_name}a", cidr="10.0.1.0/24"),
    Subnet_Bundle(subnet_name="SubNet2", az=f"{region_name}b", cidr="10.0.2.0/24"),
]


inst_profiles = [
    "AWS_EC2_INSTANCE_PROFILE_ROLE",
]

log_groups = ["nginx", "flask", "mongodb"]


class EC2_instance:
    def __init__(self):
        self.type = "t2.micro"
        self.ami = "ami-0fc61db8544a617ed"
        self.userdata = "~/gitrepos/jouell/shouldipickitup/user_data.http.AWS.sh"
        self.cpu_scaling_file = "cpu.json"
        self.lc_name = "Auto-Scaling-Launch-Config-Docker-v1"


class LoadBalancer:
    def __init__(self):
        self.name = "My-Web-Load-Balancer"
        self.targets = "My-Web-Targets"
        self.port = 80
        self.proto = "HTTP"
