${jsonencode({
  "data": {
    "type": "proxy",
    "attributes": {
      "label": format("%s.%s", app_name, domain),
      "note": "SL demo running as PoC",
      "tags": [],
      "ipv6_front_end": false,
      "backends": [{
        "address_fqdn": gslb_fqdn,
        "zones": [
          "Germany",
          "UK"
        ]
      }],
      "proxy_services": [{
        "service_type": "SSL HTTP",
        "load_balancing_method": "Round Robin",
        "threat_profile": null,
        "protocol": "TCP",
        "profile_settings": [{
            "host": "*",
            "uri": "*",
            "l7_profile": "",
            "waf_policy": "arch_juiceshop"
        }],
        "monitoring": {
          "type": "TCP",
          "interval": 30,
          "send_string": "GET / HTTP/1.0\r\n\r\n",
          "receive_string": null
        },
        "frontend_port": 443,
        "backend_port": 443,
        "client_connection_idle_timeout": 60,
        "insert_x_forwarded_for_header": true,
        "multiplex_http_https_requests": false,
        "alternative_trusted_source_header": null,
        "cookie_persistence": null,
        "cache_enabled": false,
        "sni_pass_through": true,
        "ssl": {
          "front_end_profiles": [{
            "host": "*",
            "profile": app_name,
          }],
          "back_end_profile": "Silverline_Server_Default"
        },
        "irules": [],
        "tcp_profile": "Modern"
      },
      {
        "service_type": "HTTP REDIRECT",
        "protocol": "TCP",
        "frontend_port": 80,
        "backend_port": 80,
        "threat_profile": null,
        "irules": []
      }]
    }
  }
})}