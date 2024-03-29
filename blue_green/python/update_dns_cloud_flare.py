#!/usr/bin/env python3


import sys
import yaml

import CloudFlare

import load_cloud_flare_config

cloud_flare_config = load_cloud_flare_config.get_cf_config()
BEARER_TOKEN = cloud_flare_config["BearerToken"]
DNS_ZONE = cloud_flare_config["DNS_ZONE"]
WWW = f"www.{DNS_ZONE}"


def update_one_dns_record(dns_name, dns_type, dns_content):
    cf = CloudFlare.CloudFlare(token=BEARER_TOKEN)
    my_cf_zone_id = cf.zones.get(params={"name": DNS_ZONE})[0]["id"]
    dns_zone_data = cf.zones.dns_records.get(my_cf_zone_id)
    # A list is returned. Pull the string out using ..[0]
    try:
        dns_record_id = [
            x["id"]
            for x in dns_zone_data
            if (x["type"] == dns_type and x["name"] == dns_name)
        ][0]
    except IndexError:
        print(f"{dns_name} does not exist")
        sys.exit(1)
    new_dns_record = {
        "name": dns_name,
        "type": dns_type,
        "ttl": 60,
        "content": dns_content,
    }
    return cf.zones.dns_records.put(my_cf_zone_id, dns_record_id, data=new_dns_record)


def create_one_dns_record(dns_name, dns_type, dns_content):
    cf = CloudFlare.CloudFlare(token=BEARER_TOKEN)
    my_cf_zone_id = cf.zones.get(params={"name": DNS_ZONE})[0]["id"]
    dns_zone_data = cf.zones.dns_records.get(my_cf_zone_id)
    new_dns_record = {
        "name": dns_name,
        "type": dns_type,
        "ttl": 60,
        "content": dns_content,
    }
    return cf.zones.dns_records.post(my_cf_zone_id, data=new_dns_record)


if __name__ == "__main__":
    print(update_one_dns_record("flywheel.justgrowthrates.com", "A", "107.21.183.125"))
    # print(update_one_dns_record(WWW, 'CNAME', '54.167.240.13'))
    # print(create_one_dns_record('flywheel.justgrowthrates.com', 'A', '54.167.240.13'))
