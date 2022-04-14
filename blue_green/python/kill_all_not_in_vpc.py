#!/usr/bin/env python3

""" This kills the infr outside the VPC """
import time
from aws_cred_objects import AWS_CREDS
from prod_build_config import (
    aws_policies,
    inst_profiles,
    roles,
    aws_profile,
    log_groups,
)

rolename = "EC2AppRole"
inst_prof = "AWS_EC2_INSTANCE_PROFILE_ROLE"

# kill launch template.


def delete_items(aws_creds):

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
                aws_creds.iam_client.detach_role_policy(
                    RoleName=role.name, PolicyArn=policy_arn
                )
            except aws_creds.iam_client.exceptions.NoSuchEntityException:
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
                aws_creds.iam_client.remove_role_from_instance_profile(
                    InstanceProfileName=inst_prof, RoleName=role.name,
                )
            except aws_creds.iam_client.exceptions.NoSuchEntityException:
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
            aws_creds.iam_client.delete_role(RoleName=role.name)
        except aws_creds.iam_client.exceptions.NoSuchEntityException:
            print(f"Role {role.name} does not exist at all")
        except Exception as e:
            print(f"Failed to Delete Role {role.name} - skipping -", e)
            pass
        else:
            print(f"Deleted Instance Role {role.name} OK")

    try:
        aws_creds.iam_client.delete_instance_profile(InstanceProfileName=inst_prof)
    except aws_creds.iam_client.exceptions.NoSuchEntityException:
        print(f"Instance Profile {inst_prof} does not exist")
    except Exception as e:
        print(f"Failed to Delete Instance Profile {inst_prof} - skipping -", e)
    else:
        print(f"Deleted Instance Profile {inst_prof} OK")

    for lg in log_groups:

        try:
            aws_creds.logs_client.delete_log_group(logGroupName=lg)
        except aws_creds.logs_client.exceptions.ResourceNotFoundException:
            print(f"Log Group {lg} does not exist")
        except Exception as e:
            print(f"Error Deleting Log Group {lg} -- skipping", e)
        else:
            print(f"No Error Deleting Log Group {lg}")

    for lb in aws_creds.elbv2_client.describe_load_balancers()["LoadBalancers"]:
        aws_creds.elbv2_client.delete_load_balancer(
            LoadBalancerArn=lb["LoadBalancerArn"]
        )
        print("LB deleted OK")

    for asg in aws_creds.as_client.describe_auto_scaling_groups()["AutoScalingGroups"]:
        aws_creds.as_client.delete_auto_scaling_group(
            AutoScalingGroupName=asg["AutoScalingGroupName"], ForceDelete=True
        )
        print("ASG Deleted OK")
        time.sleep(60)

    for lc in aws_creds.as_client.describe_launch_configurations()[
        "LaunchConfigurations"
    ]:
        aws_creds.as_client.delete_launch_configuration(
            LaunchConfigurationName=lc["LaunchConfigurationName"]
        )
        print("Launch Configs Deleted OK")
        time.sleep(3)

    for lt in aws_creds.ec2_res.meta.client.describe_launch_templates()[
        "LaunchTemplates"
    ]:
        try:
            aws_creds.ec2_res.meta.client.delete_launch_template(
                LaunchTemplateName=lt["LaunchTemplateName"]
            )
        except Exception as e:
            print(f"Problem Deleting {lt['LaunchTemplateName']}")
        else:
            print(f"Deleted {lt['LaunchTemplateName']}")

    for tg in aws_creds.elbv2_client.describe_target_groups()["TargetGroups"]:
        aws_creds.elbv2_client.delete_target_group(TargetGroupArn=tg["TargetGroupArn"])


if __name__ == "__main__":

    aws_creds = AWS_CREDS(profile_name=aws_profile)
    delete_items(aws_creds)
    print("done")
