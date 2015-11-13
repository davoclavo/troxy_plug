use Mix.Config

config :logger, :console,
  format: "--$time $metadata[$level] $message\n"

config :troxy,
  http_port: 9080,
  ssl: false,
  https_port: 9433
