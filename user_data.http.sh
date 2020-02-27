#!/bin/bash
yum update -y
yum -y install docker
yum -y install git 
BDIR="/gitrepos/shouldipickitup"
mkdir -p $BDIR 
cd $BDIR
git clone https://github.com/jouellnyc/shouldipickitup.git 
curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-`uname -s`-`uname -m` | sudo tee /usr/local/bin/docker-compose > /dev/null
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose up -d

