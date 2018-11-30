# Create AWS VPC and Deploy Apache Instances 
- Create a non-default VPC with 2 Subnets, 2 Routes, Routing Table and Internet Gateway
- Tie them all togehther
- Install Apache and set it to start using user-data (index.html serves the $(hostname))
- Expose 2 EC2 instances on the internet to only your IP address on port 22 and 80
- Tell you the public IPs and create clickable links to check
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
It will be best to start without a detached Internet Gateway or Routes

### Installing
```
git clone https://github.com/jouellnyc/AWS
```

### Usage
Edit create_aws.sh to suit your needs (Availability Zones and CIDR blocks) 
 <br />
```
./create_aws_vpc.sh 
<snip>
== Wait 2 mintutes and then check: ==
http://52.42.177.159/
http://34.211.156.125/

```

### Example 
- [Example full output](example.txt)
- [Example full verbose output](example_verbose.txt)

## Authors
[https://github.com/jouellnyc](mailto:jouellnyc@gmail.com)

## License
This project is licensed under the MIT License

## Acknowledgments
*Thanks AWS!*
