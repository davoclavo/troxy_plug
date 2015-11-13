ExUnit.start
{:ok, _} = Application.ensure_all_started(:httparrot)

defmodule PlugHelper do
  use Plug.Test

  def create_conn(server, method, path) do
    port = Application.get_env(server, :http_port)
    upstream = "localhost:" <> to_string(port)
    conn(method, path)
    |> put_req_header("host", upstream)
    |> put_private(:test_runner, self)
  end

  def call_plug(conn, plug, opts) do
    opts = plug.init(opts)
    conn
    |> plug.call(opts)
  end
end
