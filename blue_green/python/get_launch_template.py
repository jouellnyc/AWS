#!/usr/bin/env python3


import json
import boto3

client = boto3.client("ec2")

if __name__ == "__main__":

    fresponse = client.get_launch_template_data(InstanceId="i-0ee3bfe00684e6200")
    cresponse = client.get_launch_template_data(InstanceId="i-06ab8d368495ecc14")

    insts = [("flywheel", fresponse), ("crawler", cresponse)]

    for x in insts:
        with open(x[0] + ".json", "w") as write_file:
            json.dump(x[1], write_file, indent=4, sort_keys=True)
