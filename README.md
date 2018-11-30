# Create AWS VPC- 'Cloud Formation' - AWS quick setup script 
Create: a non-default VPC, 2 Subnets, Routes, Internet Gateway, tie them all togehther, then expose 2 EC2 instances publicly on the internet  to save the time in manually provisioning.

### Prerequisites
[Create an AWS account](https://aws.amazon.com)

[Create an IAM user and setup Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_cliwpsapi)

[Install AWS cli:](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)
```
pip install awscli --upgrade --user
```

### Installing
```
git clone https://github.com/jouellnyc/AWS
```

### Usage
Edit create_aws.sh to suit your needs (Availability Zones and CIDR blocks) 
 <br />
```
chmod +x create_aws.sh 
./create_aws.sh 
```

## Authors
[https://github.com/jouellnyc](mailto:jouellnyc@gmail.com)

## License
This project is licensed under the MIT License

## Acknowledgments
*Thanks AWS!*
