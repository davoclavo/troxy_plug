defmodule Troxy.Interfaces.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts Troxy.Interfaces.Plug.init([])

  test "reads the upstream from the host header" do
    conn = call_plug(@opts)
    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/json"]
  end

  test "configurable to keep the raw headers or normalize them" do
    opts = Troxy.Interfaces.Plug.init([normalize_headers?: true])
    conn = call_plug(opts)

    refute get_resp_header(conn, "Content-Type") == ["application/json"]
    assert get_resp_header(conn, "content-type") == ["application/json"]
  end

  test "configurble to synchronously the response downstream"
  test "configurble to chunk the response downstream"
  test "support SSL"

  test "rejects requests without host header" do
    assert_raise Troxy.Interfaces.Plug.Error, "upstream: missing host header", fn ->
      opts = Troxy.Interfaces.Plug.init([normalize_headers?: true])
      create_conn
      |> delete_req_header("host")
      |> Troxy.Interfaces.Plug.call(opts)
    end
  end

  defp create_conn do
    port = Application.get_env(:httparrot, :http_port)
    upstream = "localhost:" <> to_string(port)
    conn(:get, "/get")
    |> put_req_header("host", upstream)
  end

  defp call_plug(opts) do
    create_conn
    |> Troxy.Interfaces.Plug.call(opts)
  end
end
