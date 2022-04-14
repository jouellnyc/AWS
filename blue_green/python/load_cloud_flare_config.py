#!/usr/bin/env python3


import yaml

CLOAD_FLARE_CONFIG = "cloudflare.yaml"


def get_cf_config():
    with open(CLOAD_FLARE_CONFIG, "r") as file:
        return yaml.safe_load(file)


def get_bearer_token():
    return get_cf_config()["BearerToken"]


def get_dns_zone():
    return get_cf_config()["DNS_ZONE"]


if __name__ == "__main__":
    print(get_cf_config())
    print(get_bearer_token())
    print(get_dns_zone())
