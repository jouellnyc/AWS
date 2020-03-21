#!/home/john/anaconda3/bin/python3

'''
"Just use the client objects"  
https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2.html
'''

import boto3

''' Create VPC '''
cidr    = "10.0.0.0/16"
vpcname = "MyVPC3"

try:
    client    = boto3.client('ec2')
    cliresp   = client.create_vpc(CidrBlock=str(cidr))
    vpcid     = cliresp['Vpc']['VpcId']
    vpctag    = client.create_tags(Resources=[vpcid], Tags=[{ 'Key' :'Name', 'Value' : vpcname},])
except Exception as e:
    print(e)
else:
    print(f"VPC {vpcname} created and tagged OK")


''' Create Subnets in precise Availability Zones '''
sncidr1="10.0.1.0/24"
sncidr2="10.0.2.0/24"
az1="us-west-2a"
az2="us-west-2b"

try:
    subnet1    = client.create_subnet(AvailabilityZone=az1, CidrBlock=sncidr1, VpcId=vpcid)
    subnet2    = client.create_subnet(AvailabilityZone=az2, CidrBlock=sncidr2, VpcId=vpcid)
    subnet1_id = subnet1['Subnet']['SubnetId'] 
    subnet2_id = subnet2['Subnet']['SubnetId'] 
    sntag1     = client.create_tags(Resources=[subnet1_id], Tags=[{ 'Key' :'Name', 'Value' : 'SubNet1'},])
    sntag2     = client.create_tags(Resources=[subnet2_id], Tags=[{ 'Key' :'Name', 'Value' : 'SubNet2'},])
except Exception as e:
    print(e)
else:
    print(f"Subnets created OK")

'''
aws ec2 modify-subnet-attribute --subnet-id  $SUBNET1 --map-public-ip-on-launch && \
aws ec2 modify-subnet-attribute --subnet-id  $SUBNET2 --map-public-ip-on-launch && \
'''

''' Create IGW '''
try:
    igw = client.create_internet_gateway()
    igw.attach_to_vpc(VpcId=vpcid)
except Exception as e:
    print(e)
else:
    print(f"IGW created and attached OK")


