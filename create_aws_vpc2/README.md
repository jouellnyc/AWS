## Create AWS VPC and Deploy Apache Instances 
- This architecture is similar to [Amazon Scenario 1](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario1.html)
- Goal is to save the time in manually provisioning and keep costs lower during testing.
- Create a non-default VPC with 2 public Subnets, 2 Routes, Routing Table and Internet Gateway

Then Either

- Launch EC2 instances with Apache installed with public IPs, off the internet, ready to add to an Elastic Load Balancer using [create_aws_elb](https://github.com/jouellnyc/AWS/tree/master/create_aws_alb).

OR

- Launch EC2 instances with Apache installed with public IPs, off the internet, using an autoscaling group (using %cpu as scaling trigger) and auto added to an Elastic Load Balancer using [create_ec2s_autoscaling_vpc2b.sh](https://github.com/jouellnyc/AWS/tree/master/create_aws_alb).


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
