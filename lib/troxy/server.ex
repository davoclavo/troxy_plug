defmodule Troxy.Server do
  require Logger
  use Application

  def start, do: start(nil, nil)
  def start(_smthing), do: start(nil, nil)
  # def start(_type // nil _argv // nil) do
  def start(_type, _argv) do
    http_port = Application.get_env(:troxy, :http)[:port]
    https_port = Application.get_env(:troxy, :https)[:port]
    Logger.info "Starting Troxy server at http://localhost:#{http_port} and https://localhost:#{https_port}"
    # Plug.Adapters.Cowboy.http Troxy.Interfaces.Plug, [],
    #     port: http_port
    Plug.Adapters.Cowboy.https Troxy.Interfaces.Plug, [],
        port: http_port,
        password: "",
        otp_app: :troxy,
        keyfile: "priv/erl_cowboy/dummy.key",
        certfile: "priv/erl_cowboy/dummy.crt"

    Logger.info "GO!"
  end

  def stop do
    Plug.Adapters.Cowboy.shutdown(Troxy.Interfaces.Plug.HTTP)
  end
end
