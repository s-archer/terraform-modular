              { 
                    "schemaVersion": "1.15.0",
                    "class": "Device",
                    "async": true,
                    "label": "my BIG-IP declaration for declarative onboarding",
                    "Common": {
                        "class": "Tenant",
                        "hostname": "${hostname}",
                        "admin": {
                            "class": "User",
                            "userType": "regular",
                            "password": "${admin_pass}",
                            "shell": "bash"
                        },
                        "myDns": {
                            "class": "DNS",
                            "nameServers": [
                                "8.8.8.8"
                            ]
                        },
                        "myNtp": {
                            "class": "NTP",
                            "servers": [
                                "0.pool.ntp.org"
                            ],
                            "timezone": "UTC"
                        },
                        "myProvisioning": {
                            "class": "Provision",
                            "ltm": "nominal"%{ if waf_enable == true },
                            "asm": "nominal"%{ endif }%{ if dns_enable == true },
                            "gtm": "nominal"%{ endif }
                        },
                        "internal-1": {
                            "class": "VLAN",
                            "tag": 1001,
                            "mtu": 1500,
                            "interfaces": [
                                {
                                    "name": 1.1,
                                    "tagged": false
                                }
                            ]
                        },
                        "internal-self": {
                            "class": "SelfIp",
                            "address": "${internal_ip}",
                            "vlan": "internal-1",
                            "allowService": "default",
                            "trafficGroup": "traffic-group-local-only"
                        }%{ for index, ip in external_ips},
                        "external-${index + 2}": {
                            "class": "VLAN",
                            "tag": "100${index + 2}",
                            "mtu": 1500,
                            "interfaces": [
                                {
                                    "name": "1.${index + 2}",
                                    "tagged": false
                                }
                            ]
                        },
                        "external-${index + 2}-self": {
                            "class": "SelfIp",
                            "address": "${ip}",
                            "vlan": "external-${index + 2}",
                            "allowService": "none",
                            "trafficGroup": "traffic-group-local-only"
                        }%{ endfor },
                        "localRoute": {
                            "class": "Route",
                            "network": ${cidr},
                            "gw": ${internal_gw},
                        },
                        "dbvars": {
                            "class": "DbVariables",
                            "provision.extramb": 500,
                            "restjavad.useextramb": true
                        }
                    }
                }