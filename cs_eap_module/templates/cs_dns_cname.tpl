{
    "service_instance_name": "archf5.com",
    "configuration": {
        "dns_service": {
            "expire": 360000,
            "negative_ttl": 10,
            "primary_nameserver": "ns1.f5cloudservices.com",
            "records": {
                "": [
                    {
                        "ttl": 86400,
                        "type": "NS",
                        "values": [
                            "ns1.f5cloudservices.com",
                            "ns2.f5cloudservices.com"
                        ]
                    }
                ],%{ for index, each_record in a_records}
				"${each_record[0]}": [
                    {
                        "ttl": 60,
                        "type": "CNAME",
                        "value": "${eap_waf_cname[index]}"
                    }
                ],%{ endfor }
                "test": [
                    {
                        "ttl": 3600,
                        "type": "A",
                        "values": [
                            "123.45.67.89"
                        ]
                    }
                ],
                "volt": [
                    {
                        "ttl": 3600,
                        "type": "NS",
                        "values": [
                            "ns1.volterradns.io",
                            "ns2.volterradns.io",
                            "ns3.volterradns.io",
                            "ns4.volterradns.io"
                        ]
                    }
                ]
            },
            "ttl": 86400,
            "zone": "archf5.com"
        },
        "nameservers": [
            {
                "ipv4": "107.162.158.150",
                "ipv6": "2604:e180:1021::ffff:6ba2:9e96",
                "name": "ns1.f5cloudservices.com"
            },
            {
                "ipv4": "107.162.158.151",
                "ipv6": "2604:e180:1021::ffff:6ba2:9e97",
                "name": "ns2.f5cloudservices.com"
            }
        ]
    }
}

