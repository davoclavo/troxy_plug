ExUnit.start
{:ok, _} = Application.ensure_all_started(:httparrot)

defmodule Troxy.PlugHelper do
  use Plug.Test

  # def create_conn(scheme \\ :http, request_path \\ "/get" ) do
  def create_conn(server \\ :httparrot, scheme \\ :http, method \\ :get, path \\ "/get") do
    port = case {server, scheme} do
      {:troxy, _} -> Application.get_env(server, scheme)[:port]
      {:httparrot, :http} -> Application.get_env(server, :http_port)
      {:httparrot, :https} -> Application.get_env(server, :https_port)
    end

    upstream_uri = "localhost:" <> to_string(port)
    base_uri = to_string(scheme) <> "://troxy.test" <> path
    conn(method, base_uri)
    |> put_req_header("host", upstream_uri)
    |> put_private(:test_runner, self)
  end

  def init_and_call_plug(conn, plug, opts) do
    opts = plug.init(opts)
    conn
    |> plug.call(opts)
  end
end
