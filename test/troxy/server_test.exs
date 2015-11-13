defmodule Troxy.ServerTest do
  use ExUnit.Case, async: true

  defp connect_plug(plug, opts) do
    PlugHelper.create_conn(:troxy, :get, "/")
    |> PlugHelper.call_plug(plug, opts)
  end

  @tag timeout: 100
  test "rejects proxying to itself" do
    Troxy.Server.start
    assert_raise Troxy.Interfaces.Plug.Error, "upstream: can't proxy itself", fn ->
      connect_plug(Troxy.Interfaces.Plug, [])
    end
  end
end
