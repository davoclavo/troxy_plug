defmodule Router do
  use Plug.Router

  # Catch exceptions and return 500
  # override by implementing `handle_errors/2`
  use Plug.ErrorHandler
  require IEx

  # use Plug.Debugger

  plug Plug.Logger, log: :debug
  plug :match # expects you to use the match macro, also get,post,blabla
  plug :dispatch # expects a dispatch function, last possible plug

  # get "/" do
  #   send_resp(conn, 200, "hi")
  # end

  match _ do
    send_resp(conn, 200, "OKEY")
  end

  # Is this function
  def dispatch(conn, _opts) do
    send_resp(conn, 400, "CACA")
  end

end
