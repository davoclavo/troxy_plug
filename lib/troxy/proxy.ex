defmodule Troxy.Proxy do
  use Plug.Builder
  plug :authorize
  plug :is_alive
  use Troxy.Interfaces.Plug

  def authorize(conn, _opts) do
    case Plug.Conn.get_req_header(conn, "proxy-authorization") do
      ["Basic " <> encoded_auth] ->
        [username, password] = Base.decode64!(encoded_auth)
        |> String.split(":")
        configuration = Application.fetch_env!(:troxy, :auth)
        case {to_value(configuration[:username]), to_value(configuration[:password])} do
          {^username, ^password} ->
            conn
            |> Plug.Conn.delete_req_header("proxy-authorization")
          _ ->
            unauthorized_request(conn)
        end
      _ ->
        unauthorized_request(conn)
    end
  end
  defp unauthorized_request(conn) do
    conn
    |> put_private(:plug_skip_troxy, true)
    |> resp(401, "bad proxy auth")
    |> halt
  end
  defp to_value({:system, env_var}), do: System.get_env(env_var)


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
