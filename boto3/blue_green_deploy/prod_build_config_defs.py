from collections import namedtuple

Policy = namedtuple("Policy", ["name", "file", "desc"])

Role = namedtuple("Role", ["name", "file"])

EC2_Instance = namedtuple(
    "EC2_Instance", ["ami", "type", "userdata", "cpu_scaling_file"]
)

Sec_Group = namedtuple("Sec_Group", ["port", "name", "description", "proto", "myip"])

Auto_Scaling_Bundle = namedtuple(
    "Auto_Scaling_Bundle",
    ["asg_name", "asg_min_srv", "asg_max_srv", "tg_name", "tg_port", "tg_proto"],
)

Subnet_Bundle = namedtuple("Subnet_Bundle", ["cidr", "az", "subnet_name"])
