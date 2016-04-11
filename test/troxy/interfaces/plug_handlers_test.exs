defmodule Troxy.Interfaces.PlugHandlersTest do
  use ExUnit.Case, async: true
  import Troxy.PlugHelper

  defp connect_plug(plug, opts) do
    create_conn(:httparrot, :http, :get, "/get")
    |> init_and_call_plug(plug, opts)
  end

  defmodule TestPlug do
    use Plug.Builder
    use Troxy.Interfaces.Plug

    def upstream_handler(conn) do
      send conn.private[:test_runner], :from_upstream_handler
      conn
    end

    def downstream_handler(conn) do
      send conn.private[:test_runner], :from_downstream_handler
      conn
    end
  end

  test "calls upstream_handler" do
    connect_plug(TestPlug, [])
    assert_received(:from_upstream_handler)
  end

  test "calls downstream_handler" do
    connect_plug(TestPlug, [])
    assert_received(:from_downstream_handler)
  end

  defmodule TestIncompletePlug do
    use Plug.Builder
    use Troxy.Interfaces.Plug

    def upstream_handler(conn) do
      send conn.private[:test_runner], :from_upstream_handler
      conn
    end

    # No downstream_handler on purpose
  end

  test "calls upstream_handler even if not all handlers are implemented" do
    connect_plug(TestIncompletePlug, [])
    assert_received(:from_upstream_handler)
    refute_received(:from_downstream_handler)
  end
end
