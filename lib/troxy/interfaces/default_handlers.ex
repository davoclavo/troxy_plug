defmodule Troxy.Interfaces.DefaultHandlers do
  defmacro __using__(_) do
    quote location: :keep do
      @spec upstream_handler(Plug.Conn.t) :: Plug.Conn.t
      def upstream_handler(conn), do: conn

      @spec downstream_handler(Plug.Conn.t) :: Plug.Conn.t
      def downstream_handler(conn), do: conn

      defoverridable [upstream_handler: 1,
                      downstream_handler: 1]
    end
  end
end
