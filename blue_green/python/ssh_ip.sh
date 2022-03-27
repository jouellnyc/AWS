#!/bin/bash
chmod 400 *pem
ssh -o StrictHostKeyChecking=no -i *pem  ec2-user@$(./show_ip.sh)
