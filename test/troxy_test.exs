defmodule TroxyTest do
  use ExUnit.Case, async: true
  use Plug.Test

  setup_all do
    HTTParrot.start :no_type, :no_args
    :ok
  end

  @opts Troxy.init([upstream_handler: &__MODULE__.upstream_handler/1,
                    downstream_handler: &__MODULE__.downstream_handler/1])

  def upstream_handler(conn), do: conn
  def downstream_handler(conn), do: conn

  # @opts Troxy.init([])

  test "Does not allow proxying to itself" do
    conn(:get, "/")
    |> Troxy.call(@opts)
  end

  defp make_request(opts) do
    port = Application.get_env(:httparrot, :http_port)
    upstream = "localhost:" <> to_string(port)
    conn(:get, "/get")
    |> put_req_header("host", upstream)
    |> Troxy.call(opts)
  end

  test "Reads the upstream from the host header" do
    conn = make_request(@opts)
    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/json"]
  end

  test "Supports SSL" do
  end

  test "Calls upstream_handler" do
    target = self
    upstream_handler = fn conn ->
      send(target, :from_handler)
      conn
    end

    opts = Troxy.init([upstream_handler: upstream_handler])
    make_request(opts)

    assert_received(:from_handler)
  end

  test "Calls downstream handler" do
    target = self
    downstream_handler = fn conn ->
      send(target, :from_handler)
      conn
    end

    opts = Troxy.init([downstream_handler: downstream_handler])
    make_request(opts)

    assert_received(:from_handler)
  end

  test "Can configure to keep the raw headers or normalize them" do
    opts = Troxy.init([normalize_headers?: true])
    conn = make_request(opts)

    refute get_resp_header(conn, "Content-Type") == ["application/json"]
    assert get_resp_header(conn, "content-type") == ["application/json"]
  end

  test "Can configure to synchronously the response downstream" do
  end

  test "Can configure to chunk the response downstream" do
  end

end
