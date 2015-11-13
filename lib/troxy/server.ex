defmodule Troxy.Server do
  require Logger
  use Application

  def start, do: start(nil, nil)
  def start(_smthing), do: start(nil, nil)
  # def start(_type // nil _argv // nil) do
  def start(_type, _argv) do
    port = Application.get_env(:troxy, :http_port)
    Logger.info "Starting Troxy server at http://localhost:#{port}"
    Plug.Adapters.Cowboy.http Troxy.Interfaces.Plug, [],
        port: port
        # password: "SECRET",
        # otp_app: :troxy,
        # keyfile: "priv/ssl/key.pem",
        # certfile: "priv/ssl/cert.pem"
  end

  def stop do
    Plug.Adapters.Cowboy.shutdown(Troxy.Interfaces.Plug.HTTP)
  end
end
