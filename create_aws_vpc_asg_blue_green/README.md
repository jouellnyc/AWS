## Create AWS VPC and Deploy Apache Instances 

- Build:
- VPC with 2 public Subnets, 2 Routes, Routing Table and Internet Gateway
- Elastic Load Balancer, EC2s launched via autoscaling group using %cpu as scaling trigger.
- Extra Infra to perform BLUE-Green updgrades


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
It will always be *best* to start from scratch with a new VPC.

The process should take between 5-10 min on average.

Use tear_down to tear down.

### Installing
```
git clone https://github.com/jouellnyc/AWS
```

### Usage
```
source create_aws_vpc3.sh 
source create_lb_autoscaling_ec2.sh
```

## Authors
[jouellnyc](mailto:jouellnyc@gmail.com)

## License
This project is licensed under the MIT License

## Acknowledgments
*Thanks AWS!*
