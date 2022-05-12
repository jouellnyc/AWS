#!/bin/bash
MP=$(ls -1  *pem | tail -n 1)
mv $MP /tmp/
rm -f *pem
mv /tmp/$MP .
chmod 400 *pem
ssh -o StrictHostKeyChecking=no -i *pem  ec2-user@$(./show_ip.sh)
