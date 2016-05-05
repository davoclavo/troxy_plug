defmodule Troxy.Interfaces.DefaultHandlers do
  defmacro __using__(_) do
    quote location: :keep do
      @spec req_handler(Plug.Conn.t) :: Plug.Conn.t
      def req_handler(conn), do: conn

      @spec resp_handler(Plug.Conn.t) :: Plug.Conn.t
      def resp_handler(conn), do: conn

      @spec req_body_handler(Plug.Conn.t, String.t, boolean) :: Plug.Conn.t
      def req_body_handler(conn, _body_chunk, _more_body), do: conn


      @spec resp_body_handler(Plug.Conn.t, String.t, boolean) :: Plug.Conn.t
      def resp_body_handler(conn, _body_chunk, _more_body), do: conn

      defoverridable [req_handler: 1,
                      resp_handler: 1,
                      req_body_handler: 3,
                      resp_body_handler: 3]
    end
  end
end
