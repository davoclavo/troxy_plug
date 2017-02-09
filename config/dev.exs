use Mix.Config

config :logger, :console,
  format: "--$time $metadata[$level] $message\n"

config :troxy,
  http: [
    port: 9080,
  ],
  https: [
    port: 9943,
    password: "mypassword",
    keyfile: "priv/erl_cowboy/dummy.key",
    certfile: "priv/erl_cowboy/dummy.crt"
  ]
