#!/bin/bash
rm -f *pem
./kill_all_not_in_vpc.py
./kill_all_vpc.py 
./kill_all_not_in_vpc.py
./kill_all_vpc.py
