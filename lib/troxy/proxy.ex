defmodule Troxy.Proxy do
  use Plug.Builder
  plug :rewrite_troxy_host_header
  plug :is_alive
  use Troxy.Interfaces.Plug

  def rewrite_troxy_host_header(conn, _opts) do
    case Plug.Conn.get_req_header(conn, "x-troxy-host") do
      [] ->
        conn
      [target_host] ->
        # Added the peer to temporarily allow requests from the ui
        %Plug.Conn{conn | host: target_host, peer: {{127,0,0,2}, 111317}}
        |> delete_req_header("x-troxy-host")
        |> delete_req_header("host")
        |> put_req_header("host", target_host)
    end
  end

  def is_alive(conn, opts) do
    if File.exists?("partition.lock") do
      conn = conn
      |> put_private(:plug_skip_troxy, true)
      |> resp(502, "bad proxy")
      |> halt
    end
    conn
  end

  def req_handler(conn), do: conn

  def req_body_handler(conn, _body_chunk, _more_body), do: conn

  def resp_handler(conn) do
    if conn.status in [401, 403] do
      {:ok, file} = File.open "partition.lock", [:write]
      IO.binwrite file, "lock"
      File.close file
    end
    conn
  end

  def resp_body_handler(conn, _body_chunk, _more_body), do: conn
end
