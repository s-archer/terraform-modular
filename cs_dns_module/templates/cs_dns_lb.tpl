${jsonencode({
    "account_id": account_id ,
    "catalog_id": "c-aaQnOrPjGu",
    "plan_id": "p-__free_dns",
    "service_instance_name": gslb_zone_a_record,
    "service_type": "gslb",
    "configuration": {
        "gslb_service": {
			"zone": gslb_zone,
			"load_balanced_records": {
				"lbr1": {
					"aliases": [
						gslb_zone_a_record
					],
					"rr_type": "A",
					"display_name": gslb_zone_a_record,
					"enable": true,
					"persistence": false,
					"persist_cidr_ipv4": 24,
					"persist_cidr_ipv6": 56,
					"persistence_ttl": 3600,
					"proximity_rules": [
						{
							"region": "global",
							"pool": gslb_zone_a_record,
							"score": 1
						}
					]
				}
			},
			"pools": {
				format("%s", gslb_zone_a_record ) : {
					"display_name": gslb_zone_a_record,
					"enable": true,
					"remark": "",
					"rr_type": "A",
					"ttl": 30,
					"load_balancing_mode": "round-robin",
					"max_answers": 1,
					"members": [for index, each_bip in gslb_pub_vs_eips_list :
						{
							"virtual_server": format("%s_%s", gslb_zone_a_record , index ),
							"monitor": "tcp_monitor"
						} 
					]
				}
			},
			"virtual_servers": { for index, each_bip in gslb_pub_vs_eips_list :
				format("%s_%s", gslb_zone_a_record , index ) => {
					"virtual_server_type": "cloud",
					"display_name": each_bip.public_dns,
					"port": 443,
					"address": each_bip.public_ip,
					"monitor": "tcp_monitor"
				}
			},
			"monitors": {
				"tcp_monitor": {
					"display_name": "tcp_standard",
					"monitor_type": "tcp_standard",
					"target_port": 443
				}
			}
		}
	}
})}

