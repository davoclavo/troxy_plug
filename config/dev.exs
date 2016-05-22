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
    keyfile: "/tmp/server.key",
    certfile: "/tmp/server.crt",
  ]

config :hackney,
  mod_metrics: Troxy.Metrics.Elixometer
  # mod_metrics: Troxy.Metrics.Exometer
  # mod_metrics: :exometer
  # mod_metrics: :folsom

# config :exometer_core,
#   report: [
#     reporters: [{:exometer_report_tty, []}]
#   ]

# config :elixometer,
#   reporter: :exometer_report_tty,
#   env: Mix.env,
#   metric_prefix: "troxy"

config :elixometer, reporter: :exometer_report_influxdb,
  update_frequency: 5_000,
  env: Mix.env,
  metric_prefix: "troxy"

config :exometer_core, report: [
  reporters: [
    # exometer_report_tty: [],
    exometer_report_influxdb: [
      protocol: :http,
      host: "localhost",
      port: 8086,
      db: "dev"
    ]
  ]
]

# config :exometer,
#   # subscriptions: [
#   #   {:exometer_report_influxdb, [:erlang, :memory], :total, 5000, [{:tags, {:tag, :value}}]},
#   # ],
#   reporters: [
#     # exometer_report_tty: [],
#     exometer_report_influxdb: [
#       protocol: :http,
#       host: "localhost",
#       port: 8086,
#       db: "dev"
#     ]
#   ]
