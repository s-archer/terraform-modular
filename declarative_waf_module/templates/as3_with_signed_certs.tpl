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
            "class": "Tenant"%{ for index, app in app_list},
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
                    "serverTLS": "${app[0]}Tls"%{ if waf_enable == true },
                    "policyWAF": {
                        "use": "owaspPolicy" 
                    }%{ endif }
                },             
                "${app[0]}Tls": {
                    "class": "TLS_Server",
                    "certificates": [
                        {
                            "certificate": "${app[0]}_cert"
                        }
                    ],
                    "tls1_0Enabled": false,
                    "tls1_1Enabled": false,
                    "cipherGroup": {
                        "bigip": "/Common/f5-secure"
                    }
                },  
                "${app[0]}_cert": {
                  "class": "Certificate",
                  "certificate": ${jsonencode(app[2])},
                  "privateKey": ${jsonencode(app[3])}
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
                }%{ if waf_enable == true },
                "owaspPolicy": {
                    "class": "WAF_Policy",
                    "url": "https://raw.githubusercontent.com/s-archer/waf_policies/master/owasp.json",
                    "ignoreChanges": false,
                    "enforcementMode": "blocking"
                }%{ endif }
            }%{ endfor }
        }
    }
}