#!/bin/bash

# Check if PROFILES exist and match; or exit

if [ -z "$DEFAULT_AWS_PROFILE" -a -z "$AWS_PROFILE" ];then
   echo "DEFAULT_AWS_PROFILE and AWS_PROFILE are not set"
   exit 2
fi

if [ ! "$DEFAULT_AWS_PROFILE" =  "$AWS_PROFILE" ];then
   echo "DEFAULT_AWS_PROFILE and AWS_PROFILE do not match!"
   echo "$DEFAULT_AWS_PROFILE and $AWS_PROFILE"
   exit 2
fi
