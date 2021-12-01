#!/bin/bash

IP=$1
SLEEP=$2
sleep $SLEEP; ssh -oStrictHostKeyChecking=no -i vpc-*st*.pem ec2-user@"${IP}" "sudo -- bash -c 'cd
/gitrepos/stocks_web/ && ./non-app/master.enter.sh flask'"
