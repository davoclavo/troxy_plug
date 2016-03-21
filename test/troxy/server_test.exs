defmodule Troxy.ServerTest do
  use ExUnit.Case, async: true
  import Troxy.PlugHelper

  @tag timeout: 100
  test "rejects proxying to itself" do
    Troxy.Server.start
    assert_raise Troxy.Interfaces.Plug.Error, "upstream: can't proxy itself", fn ->
      create_conn(:troxy, :http, :get, "/")
      |> init_and_call_plug(Troxy.Interfaces.Plug, [])
    end
  end
end
