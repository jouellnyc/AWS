#!/usr/bin/env python3

import sys
import time
from aws_cred_objects import AWS_CREDS


""" This kills the VPCs after all the Infra outside the VPC is deco'ed """


def vpc_delete(vpcid, aws_creds):

    aws_creds.ec2client = aws_creds.ec2_res.meta.client
    vpc = aws_creds.ec2_res.Vpc(vpcid)
    dhcp_options_default = aws_creds.ec2_res.DhcpOptions("default")

    if not vpcid:
        print("== No VPCs here ==")
        return
    print(f"== Starting of Removal of VPC ({vpcid}) from AWS ==")

    if dhcp_options_default:
        dhcp_options_default.associate_with_vpc(VpcId=vpc.id)
    for gw in vpc.internet_gateways.all():
        vpc.detach_internet_gateway(InternetGatewayId=gw.id)
        gw.delete()
    for rt in vpc.route_tables.all():
        for rta in rt.associations:
            if not rta.main:
                rta.delete()
    for subnet in vpc.subnets.all():
        for instance in subnet.instances.all():
            instance.terminate()
    for ep in aws_creds.ec2client.describe_vpc_endpoints(
        Filters=[{"Name": "vpc-id", "Values": [vpcid]}]
    )["VpcEndpoints"]:
        aws_creds.ec2client.delete_vpc_endpoints(VpcEndpointIds=[ep["VpcEndpointId"]])

    """
    
    These will all need time/waiterers
    
    """

    """ Find the SG's w/dependencies """
    is_dep = []
    print("Checking Security Groups for dependencies")
    for sec_group in aws_creds.ec2_res.meta.client.describe_security_groups()[
        "SecurityGroups"
    ]:

        try:

            if sec_group["GroupName"] == "default":
                print(f"Passing on SG {sec_group['GroupName']}")
                continue
            try:
                dest_group = sec_group["IpPermissions"][0]["UserIdGroupPairs"][0][
                    "GroupId"
                ]
            except IndexError:
                print(
                    f"SG {sec_group['GroupName']} {sec_group['GroupId']} does not have a group dependancy"
                )
                pass
            else:
                print(
                    f"SG {sec_group['GroupName']} {sec_group['GroupId']} has a "
                    f"dependency on group {dest_group}"
                )
                is_dep.append(sec_group)
        except Exception as e:
            print(e)

    """ Delete the SG's w/dependencies now -- We don't know what order """
    """ AWS will return the groups so we can't just kill them above    """

    print("Deleting groups with dependencies")
    for sec_group in is_dep:

        try:
            aws_creds.ec2_res.meta.client.delete_security_group(
                GroupId=sec_group["GroupId"]
            )
            time.sleep(10)
        except Exception as e:
            print(e)
        else:
            print(f"Deleted SG {sec_group['GroupName']}  {sec_group['GroupId']}")

    """ Rerun now against all  groups not that those w/deps are gone """
    print("Deleting groups w/o dependencies")
    for sec_group in aws_creds.ec2_res.meta.client.describe_security_groups()[
        "SecurityGroups"
    ]:
        try:
            if sec_group["GroupName"] == "default":
                continue
            else:
                aws_creds.ec2_res.meta.client.delete_security_group(
                    GroupId=sec_group["GroupId"]
                )
        except Exception as e:
            print(e)
        else:
            print(f"Deleted SG {sec_group['GroupName']}  {sec_group['GroupId']}")

    for vpcpeer in aws_creds.ec2client.describe_vpc_peering_connections(
        Filters=[{"Name": "requester-vpc-info.vpc-id", "Values": [vpcid]}]
    )["VpcPeeringConnections"]:
        aws_creds.ec2_res.VpcPeeringConnection(
            vpcpeer["VpcPeeringConnectionId"]
        ).delete()
    for netacl in vpc.network_acls.all():
        if not netacl.is_default:
            netacl.delete()
    for subnet in vpc.subnets.all():
        for interface in subnet.network_interfaces.all():
            interface.delete()
        subnet.delete()
    aws_creds.ec2client.delete_vpc(VpcId=vpcid)


if __name__ == "__main__":

    aws_creds = AWS_CREDS(profile_name="dev")
    vpc_to_ignore = "PROD-VPC"

    try:

        count = 0

        for vpc in aws_creds.ec2_res.vpcs.all():
            try:
                if vpc.tags[0]["Value"] != vpc_to_ignore:
                    vpc_delete(vpc.id)
                    count += 1
            except TypeError:
                resp = vpc_delete(vpc.id, aws_creds)
                if resp is None:
                    count += 1

    except Exception as e:

        print(
            f"Uncaught Error: type({e}), {e} Error on line ",
            sys.exc_info()[-1].tb_lineno,
        )

    else:

        print(f"{count} VPCs Deleted.")
