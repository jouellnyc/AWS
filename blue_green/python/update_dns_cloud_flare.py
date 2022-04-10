#!/usr/bin/env python3


import yaml

import CloudFlare

import load_cloud_flare_config

cloud_flare_config         = load_cloud_flare_config.get_cf_config()
BEARER_TOKEN               = cloud_flare_config['BearerToken']
DNS_ZONE                   = cloud_flare_config['DNS_ZONE']
WWW                        = f"www.{DNS_ZONE}"

def update_one_dns_record(dns_name, dns_type, dns_content):
    cf                         = CloudFlare.CloudFlare(token=BEARER_TOKEN)
    my_cf_zone_id              = cf.zones.get(params = {'name': DNS_ZONE })[0]['id']
    dns_zone_data              = cf.zones.dns_records.get(my_cf_zone_id)
    dns_record_id    = [ x['id'] for x in dns_zone_data if (x['type'] == dns_type and x['name'] == WWW)][0]

    new_dns_record = {'name':dns_name, 'type':dns_type, 'ttl': 60, 'content': dns_content}
    return cf.zones.dns_records.put(my_cf_zone_id, dns_record_id, data=new_dns_record)

if __name__ == '__main__':

    print(update_one_dns_record(WWW, 'CNAME', 'hello5.aws.com'))
