{
    "class": "AS3",
    "action": "deploy",
    "persist": true,
    "declaration": {
        "class": "ADC",
        "schemaVersion": "3.22.0",
        "label": "Demo AWS v1.2",
        "remark": "Simple AS3 template for Terraform expansion",
        "demo_tenant": {
            "class": "Tenant"%{ for app in app_list},
            "${app[0]}": {
                "class": "Application",
                "HTTPS_${app[0]}": {
                    "class": "Service_HTTPS",
                    "virtualPort": 443,
                    "redirect80": false,
                    "virtualAddresses": [
                        "${app[5]}"
                    ],
                    "persistenceMethods": [],
                    "profileMultiplex": {
                        "bigip": "/Common/oneconnect"
                    },
                    "pool": "${app[0]}_pool",
                    "serverTLS": "${app[0]}Tls"
                },
                "${app[0]}Tls": {
                    "class": "TLS_Server",
                    "certificates": [
                        {
                            "certificate": "${app[0]}_cert"
                        }
                    ]
                },  
                "${app[0]}_cert": {
                  "class": "Certificate",
                  "certificate": "${app[2]}",
                  "privateKey": "${app[3]}"
                },
                "${app[0]}_pool": {
                    "class": "Pool",
                    "monitors": [
                        "http"
                    ],
                    "members": [
                        {
                            "servicePort": 80,
                            "addressDiscovery": "aws",
                            "updateInterval": 1,
                            "tagKey": "Name",
                            "tagValue": "${app[4]}",
                            "addressRealm": "private",
                            "region": "${app[6]}"
                        }
                    ]
                },
                "${app[0]}_domain": {
                    "class": "GSLB_Domain",
                    "domainName": "${format("%s.%s", app[0], app[1])}",
                    "resourceRecordType": "A",
                    "poolLbMode": "ratio",
                    "pools": [
                                { "use": "${app[0]}_gslb_pool" }
                    ]
                },
                "${app[0]}_gslb_pool": {
                    "class": "GSLB_Pool",
                    "enabled": true,
                    "lbModeAlternate": "ratio",
                    "lbModeFallback": "ratio",
                    "manualResumeEnabled": true,
                    "verifyMemberEnabled": false,
                    "members": [
                        {
                            "ratio": 10,
                            "server": {
                                "use": "/Common/Shared/gslbServer"
                            },
                            "virtualServer": "${app[0]}_vs_1"
                        },
                        {
                            "ratio": 10,
                            "server": {
                                "use": "/Common/Shared/gslbServer"
                            },
                            "virtualServer": "${app[0]}_vs_2"
                        }
                    ],
                    "monitors": [
                        {
                            "bigip": "/Common/http"
                        }
                    ],
                    "resourceRecordType": "A",
                    "fallbackIP": "1.1.1.1"
                }
            }%{ endfor }
        },
        "Common": {
            "class": "Tenant",
            "Shared": {
                "class": "Application",
                "template": "shared",
                "aws1": {
                    "class": "GSLB_Data_Center"
                },
                "gslbServer": {
                    "class": "GSLB_Server",
                    "dataCenter": {
                        "use": "aws1"
                    },
                    "devices": [
                        {
                            "address": "${pub_vs_eips_list[0].public_ip}",
                            "addressTranslation": "${pub_vs_eips_list[0].private_ip}" 
                        }
                    ],
                    "virtualServers": [
                        {
                            "address": "10.0.2.5",
                            "port": 80,
                            "name": "arch_vs_1"
                        },
                        {
                            "address": "10.0.2.6",
                            "port": 80,
                            "name": "arch_vs_2"
                        }
                    ]
                }
            }
        }
    }
}