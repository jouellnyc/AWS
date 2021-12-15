#!/bin/bash
ssh -i *pem  ec2-user@$(./show_ip.sh)
