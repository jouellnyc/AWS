#!/usr/bin/env python3

from aws_cred_objects import AWS_CREDS
from prod_build_config import aws_profile

import boto3


"""

Cert Data will look like this:
{'CertificateSummaryList': [{'CertificateArn': 'CERT_ARN', 'DomainName': 'WWW'}], BLAH.....}

"""

def get_cert_arn():
    if __name__ == "__main__":

        aws_creds = AWS_CREDS(profile_name=aws_profile)
        cert_data = aws_creds.acm_client.list_certificates()
        cert_arn  = cert_data['CertificateSummaryList'][0]['CertificateArn']
        return cert_arn

if __name__ == "__main__":
    print(get_cert_arn())
