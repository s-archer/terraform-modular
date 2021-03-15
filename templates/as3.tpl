{
    "class": "AS3",
    "action": "deploy",
    "persist": true,
    "declaration": {
        "class": "ADC",
        "schemaVersion": "3.22.0",
        "label": "Demo AWS v1.1",
        "remark": "Simple AS3 template for Terraform expansion",
        "demo_tenant": {
            "class": "Tenant"%{ for app in app_list},
            "${app[0]}": {
                "class": "Application",
                "template": "https",
                "serviceMain": {
                    "class": "Service_HTTPS",
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
                            "region": ${app[6]}"
                        }
                    ]
                }
            }%{ endfor }
        }
    }
}