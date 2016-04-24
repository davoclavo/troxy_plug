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

    def req_handler(conn) do
      send conn.private[:test_runner], :from_req_handler
      conn
    end

    def resp_handler(conn) do
      send conn.private[:test_runner], :from_resp_handler
      conn
    end

    def req_body_handler(conn, body_chunk) do
      send conn.private[:test_runner], {:from_req_body_handler, body_chunk}
      conn
    end

    def resp_body_handler(conn, body_chunk) do
      send conn.private[:test_runner], {:from_resp_body_handler, body_chunk}
      conn
    end
  end

  test "calls req_handler" do
    connect_plug(TestPlug, [])
    assert_received(:from_req_handler)
  end

  test "calls resp_handler" do
    connect_plug(TestPlug, [])
    assert_received(:from_resp_handler)
  end

  test "calls req_body_handler" do
    connect_plug(TestPlug, [])
    assert_received({:from_req_body_handler, body_chunk})
    # TODO: make a post request with body
    assert body_chunk == ""
  end

  test "calls resp_body_handler" do
    connect_plug(TestPlug, [])
    assert_received({:from_resp_body_handler, body_chunk})
    assert body_chunk == "{\n  \"args\": {},\n  \"headers\": {\n    \"transfer-encoding\": \"chunked\",\n    \"user-agent\": \"hackney/1.4.8\",\n    \"host\": \"localhost:10080\"\n  },\n  \"url\": \"http://localhost:10080/get\",\n  \"origin\": \"127.0.0.1\"\n}"
  end

  defmodule TestIncompletePlug do
    use Plug.Builder
    use Troxy.Interfaces.Plug

    def req_handler(conn) do
      send conn.private[:test_runner], :from_req_handler
      conn
    end

    # No resp_handler on purpose
  end

  test "calls req_handler even if not all handlers are implemented" do
    connect_plug(TestIncompletePlug, [])
    assert_received(:from_req_handler)
    refute_received(:from_resp_handler)
    refute_received(:from_req_body_handler)
    refute_received(:from_resp_body_handler)
  end
end
