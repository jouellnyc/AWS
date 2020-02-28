#!/bin/bash

yum update -y

amazon-linux-extras install docker
yum -y install git 
yum -y install awslogs 

curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-`uname -s`-`uname -m` | sudo tee /usr/local/bin/docker-compose > /dev/null
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

service docker start
chkconfig docker on
service awslogsd start
chkconfig awslogsd on

BDIR="/gitrepos/"
mkdir -p $BDIR 
cd $BDIR/
git clone https://github.com/jouellnyc/shouldipickitup.git 
cd shouldipickitup
docker-compose -f docker-compose.AWS.yaml up -d
