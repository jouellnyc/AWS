## Create AWS Elastic Load Balancer for use with  Scenario 2
- This load balancer supports a architechure similar to [Amazon Scenario 2](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario2.html).

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
[Create with create_aws_vpc2](https://github.com/jouellnyc/AWS/tree/master/create_aws_vpc2)

OR

[Create with create_aws_vpc3](https://github.com/jouellnyc/AWS/tree/master/create_aws_vpc3)

### Installing
```
git clone https://github.com/jouellnyc/AWS
```

### Usage
Edit the script to suit your needs (Availability Zones and CIDR blocks) 
 <br />
```
source create_aws_elbv2.sh
```

### Example 
- [Example output](example.txt)

## Authors
[https://github.com/jouellnyc](mailto:jouellnyc@gmail.com)

## License
This project is licensed under the MIT License

## Acknowledgments
*Thanks AWS!*
