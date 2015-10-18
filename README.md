Troxy
=====

Tee Proxy

Usage
------

```
mix deps.get
mix serve
```

Use cases
---------

todo

Dependencies
------------

- Plug
- Hackney

Benchmarks
------------

todo

Todo
----

 - Tests
 - Chunked responses
   - Task.async
 - Blacklisting hosts
 - Caching
 - Generate JSON Schema
 - Web ui
   - Postman/Paw like request creator
   - View live requests in/out
   - Live proxy browser within the browser
     - Input to write URL
     - IFrame html viewer
 - Use maru as a micro web framework
   - https://github.com/falood/maru
 - Add RFC3986 parsing
   - https://github.com/marcelog/ex_rfc3986
 - Adapters


Adapters
-----

- Troxy.Client.Adapters
  - hackney
  - gun https://github.com/ninenines/gun
  - ibrowse

- API.Adapters
  - Swagger

- Auth.Adapters
  - OAuth1
  - OAuth2



Inspired on
-----------

 - mitmproxy
 - HTTP clients like Paw
 - ngrok
