![AWS](aws.png)


## What's here 

#### create_aws_vpc1 
- Create VPC with 2 public Subnets and 2 Apache servers live on the Internet  - Amazon Scenario 1
#### create_aws_vpc2
- Create VPC with 2 public Subnets and 2 Apache servers but not live on the Internet 
- Choose to launch EC2 instances:
    - a) Behind an ALB as part of a standard target group 
    - b) Behind an ALB as part of an autoscaling group 
#### create_aws_vpc3 
- Create VPC with 2 public and private Subnets, 2 NAT Gateways, 2 Apache servers both in Private Subnets - Amazon Scenario 2
#### create_aws_alb
- Create Application Load balancer for vpc2 or vp3 
#### Smaller Helper Scripts
- delete_vpc3 deletes 'Scenario 2'  VPC created with create_aws_elbv3
- create_launch_config - As the name states ... 
- update_auto_scaling - Add or Remove EC2 instances on demand
- blue-greesh - Given an AWS Web app behind an ALB, flip the Target Groups from GREEN to BLUE and back

