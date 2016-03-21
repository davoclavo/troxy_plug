use Mix.Config

config :httparrot,
  http_port: 10080,
  ssl: true,
  https_port: 10433

config :troxy,
  http: [
    port: 9080,
  ],
  https: [
    port: 9433,
    password: "mypassword",
    keyfile: "/tmp/server.key",
    certfile: "/tmp/server.crt",
  ]

config :ex_unit, capture_log: true
