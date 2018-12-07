## Create AWS VPC and Deploy Apache Instances 
- This architecture is similar to [Amazon Scenario 1](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario1.html)
- Create a non-default VPC with 2 public Subnets, 2 Routes, Routing Table and Internet Gateway
- Launch 2 EC2 instances with Apache user-data (index.html serves $(hostname))
- Apply Security Groups to keep EC2 instances off the internet but ready to [add on a load balancer](https://github.com/jouellnyc/AWS/tree/master/create_aws_alb).
- Save the time in manually provisioning and keep costs lower during testing.

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

### Expectations 
It will be best to start from scratch with a new VPC.

### Installing
```
git clone https://github.com/jouellnyc/AWS
#NOTE: user_data.http.sh is under the main repo: /AWS
```

### Usage
Edit script to suit your needs (Availability Zones and CIDR blocks) 
 <br />
```
source create_aws_vpc3.sh 
<snip>
```

### Example 
TBD

## Authors
[https://github.com/jouellnyc](mailto:jouellnyc@gmail.com)

## License
This project is licensed under the MIT License

## Acknowledgments
*Thanks AWS!*
