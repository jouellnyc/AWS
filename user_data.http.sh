#!/bin/bash
yum update -y
yum -y install httpd
service httpd start
chkconfig httpd on
/usr/bin/hostname > /var/www/html/index.html
