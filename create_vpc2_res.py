#!/home/john/anaconda3/bin/python3

'''

https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateVpc.html
https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2.html#EC2.Client.create_vpc

'''

import boto3

vpcname = "MyVPC"
vpccidr = "10.0.0.0/16"

''' Create VPC '''
try:
    ec2 = boto3.resource('ec2')
    vpc = ec2.create_vpc(CidrBlock=vpccidr)
    vpc.create_tags(Tags=[{"Key": "Name", "Value": vpcname}])
    vpc.wait_until_available()
except Exception as e:
    print("VPC Error: " + str(e))
else:
    print(f"VPC {vpcname} created OK")


''' Create Subnets '''
sncidr1="10.0.1.0/24"
sncidr2="10.0.2.0/24"
az1="us-west-2a"
az2="us-west-2b"

try:
    subnet1 = ec2.create_subnet(vpc.id,sncidr1,availability_zone=az1)
    subnet2 = ec2.create_subnet(vpc.id,sncidr2,availability_zone=az2)
except Exception as e:
    print("Subnet Error: " + str(e))
else:
    print(f"Subnets  created OK")

'''
route_table.associate_with_subnet(SubnetId=subnet.id)
# create then attach internet gateway
ig = ec2.create_internet_gateway()
vpc.attach_internet_gateway(InternetGatewayId=ig.id)
print(ig.id)

# create a route table and a public route
route_table = vpc.create_route_table()
route = route_table.create_route(
    DestinationCidrBlock='0.0.0.0/0',
    GatewayId=ig.id
)
print(route_table.id)

# Create sec group
sec_group = ec2.create_security_group(
    GroupName='slice_0', Description='slice_0 sec group', VpcId=vpc.id)
sec_group.authorize_ingress(
    CidrIp='0.0.0.0/0',
    IpProtocol='icmp',
    FromPort=-1,
    ToPort=-1
)
print(sec_group.id)

'''
