

import boto3

ami = "ami-01bbe152bf19d0289"
min = 1 
max = 1
type = "t2.micro"
zone = "us-west-2"
cidr = "10.0.0.0/16"
subnet = "10.0.0.0/25"
vpc_name = "MYVPC"

try:
    ec2 = boto3.resource('ec2')
    vpc = ec2.create_vpc(CidrBlock=cidr)
    vpc.create_tags(Tags=[{"Key": "Name", "Value": vpc_name }])
    vpc.wait_until_available()
    subnet = vpc.create_subnet(CidrBlock=subnet)
    gateway = ec2.create_internet_gateway()
    instance = ec2.create_instances(ImageId=ami, MinCount=min, MaxCount=max,
                                     InstanceType=type,Placement={
                                     'AvailabilityZone': zone},)
except Exception as e:
    print(e)
else:
    print(instance[0])
