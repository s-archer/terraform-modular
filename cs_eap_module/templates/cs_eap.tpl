${jsonencode({
    "account_id": account_id ,
    "catalog_id": "c-aa9N0jgHI4",
    "service_instance_name": app_name,
    "service_type": "waf",
    "configuration": {
        "waf_service": {
			"application": {
				"description": app_name,
				"fqdn": fqdn,
				"http": {
					"enabled": true,
					"https_redirect": true,
					"port": 80
				},
				"https": {
					"enabled": true,
					"port": 443,
					"tls": {
						"certificate_id": certificate_id
					}
				},
				"ntlm": false,
				"waf_regions": {
					"aws": {
						"eu-west-2": {
							"endpoint": {
								"dns_name": gslb_name,
								"http": {
									"enabled": true,
									"port": 80
								},
								"https": {
									"enabled": true,
									"port": 443
								}
							}
						}
					}
				}
			},
			"policy": {
				"compliance_enforcement": {
					"data_guard": {
						"cc": true,
						"enabled": true,
						"ssn": true
					},
					"sensitive_parameters": {
						"enabled": true,
						"parameters": [
							"cc_id",
							"creditcard",
							"passwd",
							"password"
						],
						"xml_attributes": [],
						"xml_elements": []
					}
				},
				"encoding": "utf-8",
				"high_risk_attack_mitigation": {
					"allowed_methods": {
						"enabled": true,
						"methods": [
							{
								"name": "GET"
							},
							{
								"name": "POST"
							},
							{
								"name": "HEAD"
							}
						]
					},
					"api_compliance_enforcement": {
						"enabled": false
					},
					"disallowed_file_types": {
						"enabled": true,
						"file_types": [
							"back",
							"bat",
							"bck",
							"bin",
							"cfg",
							"cmd",
							"com",
							"config",
							"dat",
							"dll",
							"eml",
							"exe",
							"exe1",
							"exe_renamed",
							"hta",
							"htr",
							"htw",
							"ida",
							"idc",
							"idq",
							"ini",
							"old",
							"sav",
							"save"
						]
					},
					"enabled": true,
					"enforcement_mode": "blocking",
					"geolocation_enforcement": {
						"disallowed_country_codes": [
							"CU",
							"IR",
							"KP",
							"LY",
							"SD",
							"SY"
						],
						"enabled": true
					},
					"http_compliance_enforcement": {
						"enabled": true
					},
					"ip_enforcement": {
						"enabled": true,
						"ips": []
					},
					"signature_enforcement": {
						"enabled": true
					}
				},
				"malicious_ip_enforcement": {
					"enabled": true,
					"enforcement_mode": "blocking",
					"ip_categories": [
						{
							"block": true,
							"log": true,
							"name": "mobile_threats"
						},
						{
							"block": true,
							"log": true,
							"name": "cloud_services"
						},
						{
							"block": true,
							"log": true,
							"name": "anonymous_proxies"
						},
						{
							"block": true,
							"log": true,
							"name": "phishing_proxies"
						},
						{
							"block": true,
							"log": true,
							"name": "infected_sources"
						},
						{
							"block": true,
							"log": true,
							"name": "denial_of_service"
						},
						{
							"block": true,
							"log": true,
							"name": "scanners"
						},
						{
							"block": true,
							"log": true,
							"name": "bot_nets"
						},
						{
							"block": true,
							"log": true,
							"name": "web_attacks"
						},
						{
							"block": true,
							"log": true,
							"name": "windows_exploits"
						},
						{
							"block": true,
							"log": true,
							"name": "spam_sources"
						},
						{
							"block": true,
							"log": true,
							"name": "tor_proxies"
						}
					]
				},
				"threat_campaigns": {
					"campaigns": [],
					"enabled": true,
					"enforcement_mode": "blocking"
				}
			}
		}
	}
})}

