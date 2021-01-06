#!/usr/bin/env python3

""" This kills the infr outside the VPC """

import time

from prod_build_config import log_groups

from aws_cred_objects import (
    ec2_res,
    elbv2_client,
    as_client,
    iam_client,
    profile_name,
    logs_client,
)

from prod_build_config import aws_policies, inst_profiles, roles

rolename = "EC2AppRole"
inst_prof = "AWS_EC2_INSTANCE_PROFILE_ROLE"


def delete_items(ec2_res, as_client, iam_client, logs_client, profile_name):

    """
    my_policies = iam_client.list_policies(Scope="Local")["Policies"]
    if len(my_policies) < 1:
        print("No local Policies")
    else:
        for x in my_policies:
            # print(x["PolicyName"])
            try:
                iam_client.delete_policy(PolicyArn=x["Arn"])
            except Exception as e:
                print("Failed to Delete Policy x['PolicyName'] - skipping -", e)
                pass
            else:
                print(f"Deleted Policy {x['PolicyName']} OK")
    """

    for role in roles:

        for policy_arn in aws_policies:

            try:
                iam_client.detach_role_policy(RoleName=role.name, PolicyArn=policy_arn)
            except iam_client.exceptions.NoSuchEntityException:
                print(f"Policy {policy_arn} does not exist in {role.name}")
            except Exception as e:
                print(
                    f"Failed to Remove {policy_arn} from Profile {role.name} - skipping ",
                    e,
                )
                pass
            else:
                print(f"Removed  {policy_arn} from Profile {role.name}  OK")

        for inst_prof in inst_profiles:

            try:
                iam_client.remove_role_from_instance_profile(
                    InstanceProfileName=inst_prof, RoleName=role.name,
                )
            except iam_client.exceptions.NoSuchEntityException:
                print(f"Role {role.name} does not exist in {inst_prof}")
            except Exception as e:
                print(
                    f"Failed to Remove {rolename} from Profile {inst_prof} - skipping ",
                    e,
                )
                pass
            else:
                print(f"Removed Role {rolename} from Profile {inst_prof} OK")

        try:
            iam_client.delete_role(RoleName=role.name)
        except iam_client.exceptions.NoSuchEntityException:
            print(f"Role {role.name} does not exist at all")
        except Exception as e:
            print(f"Failed to Delete Role {role.name} - skipping -", e)
            pass
        else:
            print(f"Deleted Instance Role {role.name} OK")

    try:
        iam_client.delete_instance_profile(InstanceProfileName=inst_prof)
    except iam_client.exceptions.NoSuchEntityException:
        print(f"Instance Profile {inst_prof} does not exist")
    except Exception as e:
        print(f"Failed to Delete Instance Profile {inst_prof} - skipping -", e)
    else:
        print(f"Deleted Instance Profile {inst_prof} OK")

    for lg in log_groups:

        try:
            logs_client.delete_log_group(logGroupName=lg)
        except logs_client.exceptions.ResourceNotFoundException:
            print(f"Log Group {lg} does not exist")
        except Exception as e:
            print(f"Error Deleting Log Group {lg} -- skipping", e)
        else:
            print(f"No Error Deleting Log Group {lg}")

    try:

        for lb in elbv2_client.describe_load_balancers()["LoadBalancers"]:
            elbv2_client.delete_load_balancer(LoadBalancerArn=lb["LoadBalancerArn"])
            print("LB deleted OK")

        for asg in as_client.describe_auto_scaling_groups()["AutoScalingGroups"]:
            as_client.delete_auto_scaling_group(
                AutoScalingGroupName=asg["AutoScalingGroupName"], ForceDelete=True
            )
            print("ASG Deleted OK")
            time.sleep(60)

        for lc in as_client.describe_launch_configurations()["LaunchConfigurations"]:
            as_client.delete_launch_configuration(
                LaunchConfigurationName=lc["LaunchConfigurationName"]
            )
            print("Launch Configs Deleted OK")
            time.sleep(3)

        for tg in elbv2_client.describe_target_groups()["TargetGroups"]:
            elbv2_client.delete_target_group(TargetGroupArn=tg["TargetGroupArn"])
            print("Target Groups Deleted OK")

    except Exception as e:

        print("Error Deprovisioning: ", e)

    else:
        print("No Errors Deprovisioning")


if __name__ == "__main__":

    try:

        delete_items(ec2_res, as_client, iam_client, logs_client, profile_name)

    except Exception as e:

        print(type(e), e)

    else:

        print("done")