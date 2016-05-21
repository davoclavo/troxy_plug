Troxy
=====

Tee Proxy

Usage
------

Get [hex](http://hex.pm) dependencies

```
mix deps.get
```

Run server on iex

```
iex -S mix server
```

Close it by pressing `C-c` twice, or typing `Troxy.Server.stop`

open [troxy.space](http://troxy.space)

Useful modules are:
-----------

- Troxy.Interfaces.Plug
  + Troxy.Interfaces.DefaultHandlers
- Troxy.Server

Dependencies
------------

- Plug
- Hackney


Todo
----

 - Blacklisting hosts
 - Caching
   - We forward headers upstream, so at least we could check those are not expired and reply without sending a request to upstream
 - Generate JSON Schema, RAML, Swagger
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
 - Benchmarks

- 429496729 Concurrent clients
{ClientIP, ServerIP, ClientPort, ServerPort}.
https://news.ycombinator.com/item?id=10501058


Adapters
-----

- Client.Adapters
  + [hackney](https://github.com/benoitc/hackney)
  + [gun](https://github.com/ninenines/gun)
  + [ibrowse](https://github.com/cmullaparthi/ibrowse)

- API.Adapters
  + JSON Schema
  + RAML
  + API Blueprint
  + Swagger

- Auth.Adapters
  + OAuth1
  + OAuth2
  + https://getkong.org/plugins/#authentication

Inspired on
-----------

 - mitmproxy, charles
 - HTTP clients like paw, postman
 - ngrok

Similar projects
----

 - [elixir-reverse-proxy](https://github.com/slogsdon/elixir-reverse-proxy)

Tests
------

In order to be able to pry, call with `iex -S` and set `--trace`
`iex -S mix test --trace --exclude not_implemented:true test/troxy`
