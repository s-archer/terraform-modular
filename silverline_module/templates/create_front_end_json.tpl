${jsonencode({
  "data": {
    "type": "ssl_profile",
    "attributes": {
      "name": app_name,
      "profile_type": "parent",
      "secure_renegotiation_type": "request",
      "ssl_certificate": app_name,
      "ssl_cipher": "compatible",
      "ciphers": ""
    }
  }
})}