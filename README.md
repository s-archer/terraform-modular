# terraform-modular

The app_list initial format is:

```
[
  "< 0 app short name>",
  "< 1 gslb domain name>",
  "< 2 placeholder TLS certificate>"
  "< 3 placeholder TLS key>"
  "< 4 AWS 'Name' tag value to identify pool member servers>"
]
```

As this variable passes through the modules, extra fields are added, eventually looking like this:

```
[
  "< 0 app short name>",
  "< 1 gslb domain name>",
  "< 2 placeholder TLS certificate - LETS ENCRYPT MODULE REPLACES: with signed cert>"
  "< 3 placeholder TLS key - LETS ENCRYPT MODULE REPLACES: with new key>"
  "< 4 AWS 'Name' tag value to identify pool member servers>"
  "< 5 BIG-IP MODULE ADDS: VS private IP>",
  "< 6 BIG-IP MODULE ADDS: AWS Region>",
  "< 7 BIG-IP MODULE ADDS: VS Public IP>",
  "< 8 CS_DNS MODULE ADDS: GSLB FQDN>",
  "< 9 LETS ENCRYPT MODULE ADDS: intermediate certificate>"
]
```

app_list is nested as json as follows:

[
  bigip1[
    app1[ 
      val1
      val2
      ...
    ]
    app2[ 
      val1
      val2
      ...
    ]
  ], 
  bigip2[
    app1[ 
      val1
      val2
      ...
    ]
    app2[ 
      val1
      val2
      ...
    ]
  ]
]