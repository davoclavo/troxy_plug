use Mix.Config

config :httparrot,
  http_port: 10007,
  ssl: true,
  https_port: 10008

config :troxy,
  http_port: 11007
  # ssl: true,
  # https_port: 11008

config :ex_unit, capture_log: true
