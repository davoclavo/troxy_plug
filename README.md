Troxy
=====

Another Elixir HTTP Proxy Plug

Features
----------

- Attachable handlers to intercept the request/response at different stages
- Streaming request/response

Usage
------

### As a plug:

Add troxy to your `mix.exs` dependencies:

```

defp deps do
  [
    ...
    {:troxy, git: "https://gitlab.com/davoclavo/troxy.git" }
  ]
end
```

Plug it in your endpoint/router/controller

```
plug Troxy.Interfaces.Plug
```

### As a Troxy pipeline, if you want to intercept the connection at different stages. (Works but still has a few issues)

```
defmodule MyApp.Troxy.Pipeline do
  use Plug.Builder
  use Troxy.Interfaces.Plug
  
  def req_handler(conn) do
    # Do something with the request path or headers
    conn
  end
  
  def req_body_handler(conn, body_chunk, more_body) do
    # Do something with a chunk of the request body
    conn
  end

  def resp_handler(conn) do
    # Do something with the response status or headers
    conn
  end
  
  def resp_body_handler(conn, body_chunk, more_body) do
    # Do something with a chunk of the response body
    conn
  end
end
```

and then plug it in your endpoint/router/controller




### Standalone (for development)

Get [hex](http://hex.pm) dependencies

```
mix deps.get
```

Run server on iex

```
iex -S mix server
```

Set your proxy to `localhost:9080`

Useful modules
-----------

- Troxy.Interfaces.Plug
  + Troxy.Interfaces.DefaultHandlers
- Troxy.Server

Dependencies
------------

- Plug
- Hackney

Similar projects
----

 - [Jose Valim's proxy](https://github.com/josevalim/proxy/blob/master/lib/proxy.ex)
 - [elixir-reverse-proxy](https://github.com/slogsdon/elixir-reverse-proxy)

Tests
------

`mix test`

In order to be able to pry, call with `iex -S` and set `--trace`
`iex -S mix test --trace --exclude not_implemented:true test/troxy`


Todo
----

 - Synchronous request/response
 - Intercept body chunks
 - hackney metrics
 - Whitelisting/Blacklisting hosts
 - Caching
   - We forward headers upstream, so at least we could check those are not expired and reply without sending a request to upstream
 - RFC3986 parsing
   - https://github.com/marcelog/ex_rfc3986
 - Adapters
   - Client.Adapters
     + [hackney](https://github.com/benoitc/hackney)
     + [gun](https://github.com/ninenines/gun)
     + [ibrowse](https://github.com/cmullaparthi/ibrowse)
 - Benchmarks
    - 429496729 Concurrent clients {ClientIP, ServerIP, ClientPort, ServerPort}. https://news.ycombinator.com/item?id=10501058
