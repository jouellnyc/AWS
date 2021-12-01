## Create AWS VPC and Setup Up Blue Green Deployment Capability

Build:
- VPC with 2 public Subnets, 2 Routes, Routing Table and Internet Gateway
- Elastic Load Balancer, EC2s launched via autoscaling group using %cpu as scaling trigger.
- Extra Infra to perform BLUE-Green upgrades

![Blue-Green](blue_green.png)

### Expectations 
It will always be *best* to start from scratch with a new VPC.

The process should take between 2-4 min on average.


### Installing
```
git clone https://github.com/jouellnyc/AWS
```

### Usage
- cd boto3/blue_green_deploy

- set your profle name (~/.aws/credentials|aws configure) in prod_vpc_lb_builder.py.

- edit prod_build_config.py to taste. 

- python3 ./prod_vpc_lb_builder.py

(I suggest Using Spyder or a REPL - that way you can print the 'prod_vpc' object easily to debug.)
![Spyder](images/spyder.png)

### Deco
- Run kill_all_not_in_vpc.py
- Run kill_all_vpc.py

## Authors
[jouellnyc](mailto:jouellnyc@gmail.com)

## License
This project is licensed under the MIT License
