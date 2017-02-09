defmodule Troxy.Proxy do
  use Plug.Builder
  plug :is_alive
  use Troxy.Interfaces.Plug

  def is_alive(conn, opts) do
    if File.exists?("partition.lock") do
      conn = conn
      |> put_private(:plug_skip_troxy, true)
      |> resp(502, "bad")
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
