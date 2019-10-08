## Create AWS VPC and Deploy Apache Instances 

- This architecture is similar to [Amazon Scenario 1](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario1.html)
- Goal: save the time manually provisioning and keep costs lower for testing (NAT gateways are not free).
- Create a non-default VPC with 2 public Subnets, 2 Routes, Routing Table and Internet Gateway

Then Either

- Launch EC2 instances with Apache installed with public IPs but not exposed to the internet using [create_ec2s_vpc2a.sh](https://github.com/jouellnyc/AWS/blob/master/create_aws_vpc2/create_ec2s_vpc2a.sh)
- Add to an Elastic Load Balancer using [create_aws_elb](https://github.com/jouellnyc/AWS/tree/master/create_aws_alb).

OR

- Launch EC2 instances with Apache installed with public IPs, not exposed to the internet, using an autoscaling group (using %cpu as scaling trigger) and auto add to an Elastic Load Balancer using [create_ec2s_autoscaling_vpc2b.sh](https://github.com/jouellnyc/AWS/blob/master/create_aws_vpc2/create_ec2s_autoscaling_vpc2b.sh).


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
It will always be best to start from scratch with a new VPC.
In the future the script can integrate more  error checking

### Installing
```
git clone https://github.com/jouellnyc/AWS
#NOTE: user_data.http.sh is under the main repo: /AWS
```

### Usage
Edit script to suit your needs (Your IP address, Availability Zones and CIDR blocks) 
 <br />
```
source create_aws_vpc2.sh && \ 
source create_ec2s_vpc2a.sh && \
source ../create_aws_alb/create_aws_elbv2.sh 

OR

source create_aws_vpc2.sh && \ 
source create_ec2s_autoscaling_vpc2b.sh

<snip>
```
### Deletion for 2b
This will tear down all the resources created from source create_aws_vpc2.sh && source create_ec2s_autoscaling_vpc2b.sh

```
delete_lb_and_vpc.sh
```
### Example 
[Example 2a](https://github.com/jouellnyc/AWS/blob/master/create_aws_vpc2/example_2a.txt)

[Example 2b](https://github.com/jouellnyc/AWS/blob/master/create_aws_vpc2/example_2b.txt)


## Authors
[https://github.com/jouellnyc](mailto:jouellnyc@gmail.com)

## License
This project is licensed under the MIT License

## Acknowledgments
*Thanks AWS!*
