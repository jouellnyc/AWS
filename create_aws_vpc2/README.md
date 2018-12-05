## Create AWS VPC and Deploy Apache Instances in Private Subnets - Scenario 2
- Create non-default VPC with 4 Subnets (2 public and private), 3 Routing Tables, 1 Internet Gateway and 2 NAT Gateways
- This architechure is similar to [Amazon Scenario 2](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario2.html)
- Launch 2 EC2 instances with Apache user-data not directly exposed to the Internet (index.html serves $(hostname))
- Apply Security Groups to expose EC2 instances to the internet to only your IP address on port 22 and 80
- Save the time in manually provisioning and keep costs lower during testing.
- This is the first step; the second step is to [Create the Application Load Balancer](https://github.com/jouellnyc/AWS/tree/master/create_aws_alb)

### Prerequisites
[Create an AWS account](https://aws.amazon.com)

[Create an IAM user and setup Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_cliwpsapi)

[Install AWS cli:](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)
```
pip install awscli --upgrade --user
```
[Config aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
```
aws configure (set your KEYS/ETC)
```

### A note on Costs
This architecture uses NAT Gateways, which are not free, even when used with the free tier:
[AWS Priving](https://aws.amazon.com/vpc/pricing/)


### Installing
```
git clone https://github.com/jouellnyc/AWS
```

### Usage
Edit the script to suit your needs (Availability Zones and CIDR blocks) 
 <br />
```
./create_aws_vpc2.sh 
```

### Example 
TBD

## Authors
[https://github.com/jouellnyc](mailto:jouellnyc@gmail.com)

## License
This project is licensed under the MIT License

## Acknowledgments
*Thanks AWS!*
