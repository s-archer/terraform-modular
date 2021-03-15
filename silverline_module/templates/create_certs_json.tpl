${jsonencode({
  "data": {
    "type": "ssl_certificates",
    "attributes": {
      "name": app_name,
      "passphrase": null,
      "certificate": certificate,
      "key": key,
      "intermediates": [ { "certificate": chain } ],
      "note": "Stephen Archer Demo Cert"
    }
  }
})}
