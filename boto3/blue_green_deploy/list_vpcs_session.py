#!/usr/bin/env python3


""" This lists all the infra in the VPCs """


from aws_cred_objects import AWS_CREDS


def main(aws_creds):

    print("Profile: ", aws_creds.profile_name)
    print("== VPCs  ==")
    x = aws_creds.ec2_res.meta.client.describe_vpcs()["Vpcs"]
    if len(x) < 1:

        print("None")

    else:
        for vpc in aws_creds.ec2_res.vpcs.all():
            try:
                vpcid = vpc.id
                name = vpc.tags[0]["Value"]
            except TypeError:
                name = "No Name Set"
            except Exception as e:
                print(type(e), e)
            else:
                pass
            finally:
                print(vpcid, name)

    print("== Security Groups ==")
    x = aws_creds.ec2_res.meta.client.describe_security_groups()["SecurityGroups"]
    if len(x) < 1:
        print("None")
    else:
        for y in x:
            print(y["GroupName"], y["GroupId"])
            try:
                print(
                    "\tDepends on: ",
                    y["IpPermissions"][0]["UserIdGroupPairs"][0]["GroupId"],
                )
            except:
                pass

    print("== Subnets ==")
    for x in aws_creds.ec2_res.subnets.all():
        print(x.id)

    print("== Launch Configs  ==")
    x = aws_creds.as_client.describe_launch_configurations()["LaunchConfigurations"]
    if len(x) < 1:
        print("None")
    else:
        print([y["LaunchConfigurationName"] for y in x])

    print("== Load Balancers ==")
    x = aws_creds.elbv2_client.describe_load_balancers()["LoadBalancers"]
    if len(x) < 1:
        print("None")
    else:
        for y in x:
            print(y["LoadBalancerArn"], y["VpcId"])
            for x in y["AvailabilityZones"]:
                print(x["ZoneName"])

    print("== Auto Scaling Groups ==")
    x = aws_creds.as_client.describe_auto_scaling_groups()["AutoScalingGroups"]
    if len(x) < 1:
        print("None")
    else:
        for y in x:
            print(y["AutoScalingGroupName"])
            print(y["AvailabilityZones"])

    print("== Target Groups ==")
    x = aws_creds.elbv2_client.describe_target_groups()["TargetGroups"]
    if len(x) < 1:
        print("None")
    else:
        for y in x:
            print(y["TargetGroupName"])

    print("== Instance Profiles ==")
    x = aws_creds.iam_client.list_instance_profiles()["InstanceProfiles"]
    if len(x) < 1:
        print("None")
    else:
        for y in x:
            print(y["InstanceProfileName"])
            # print(y)
            # Basically the same as above...
            # print(iam_client.get_instance_profile(
            #   InstanceProfileName=y["InstanceProfileName"]
            # ))

    print("== Locally Managed Policies ==")
    x = aws_creds.iam_client.list_policies(Scope="Local")["Policies"]
    if len(x) < 1:
        print("None")
    else:
        for y in x:
            print(y["PolicyName"], y["Arn"])
            # print(iam_client.get_policy(PolicyArn=x['Arn']),"\n")

    """ These are not inline policies """
    print("== Roles and Attached AWS Managed Policies ==")
    for x in aws_creds.iam_client.list_roles()["Roles"]:
        print("Role:", x["RoleName"])
        for y in aws_creds.iam_client.list_attached_role_policies(RoleName=x["RoleName"])[
            "AttachedPolicies"
        ]:
            if len(y) > 1:
                print("\tPol: ", y["PolicyName"], y["PolicyArn"])
            else:
                print("No Policies")

    """  Show the actual details of the policy """
    #print(iam_client.get_role_policy(RoleName="EC2AppRole",PolicyName="CloudWatchSendPolicy"))


#print(iam_client.get_role_policy(RoleName="EC2AppRole",PolicyName="AwsSecretsPolicy"))


if __name__ == "__main__":

    aws_creds=AWS_CREDS(profile_name="prod")    
    main(aws_creds)


    