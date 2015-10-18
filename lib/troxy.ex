defmodule Troxy do
  import Plug.Conn
  require IEx
  require Logger

  # Based on Jose Valim's Proxy
  # https://github.com/josevalim/proxy/blob/master/lib/proxy.ex

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    method = conn.method |> String.downcase |> String.to_atom
    url = extract_url(conn)
    headers = extract_request_headers(conn)

    Logger.info "> #{method} #{url} #{inspect headers}"

    # Read response async
    # https://github.com/benoitc/hackney#get-a-response-asynchronously

    # Async response handler which will reply to self
    {:ok, async_handler_task} = Task.start __MODULE__, :async_response_handler, [conn, self]

    hackney_options = [
      {:follow_redirect, true}, # Follow redirects
      {:force_redirect, true},  # Force redirect even on POST
      :async,                   # Async response
      {:stream_to, async_handler_task} # Async PID handler
    # :insecure                 # Ignore SSL cert validation
    ]

    # Streaming the upstream request body
    {:ok, async_handler_task} = Task.start __MODULE__, :async_response_handler, [conn, self]
    body = :stream

    {:ok, hackney_client} = :hackney.request(method, url, headers, body, hackney_options)
    Logger.info ">> #{method} #{url}"

    conn
    |> upstream_chunked_request(hackney_client)

    # We dont need the connection, as it was passed to the :stream_to in hackney
    downstream_chunked_response(hackney_client)
  end

  # Reads the original request body and writes it to the hackney client recursively
  # Can I start reading the body before I even get it all?
  defp upstream_chunked_request(conn, hackney_client) do
    # Read a chunk of the request body
    # Plug.Conn.read_body for more info
    case read_body(conn) do
      {:more, partial_body, conn} ->
        # There is still body to be read
        :hackney.send_body(hackney_client, partial_body)
        # Read more body
        upstream_chunked_request(conn, hackney_client)

      {:ok, body, conn} ->
        # The last part of the body has been read
        :hackney.send_body(hackney_client, body)
        conn
    end
  end

  defp send_response(conn, hackney_client) do
    # Missing case
    # {:error, :timeout}
    {:ok, status, headers, hackney_client} = :hackney.start_response(hackney_client)

    Logger.info "<< #{status}"
    {:ok, body} = :hackney.body(hackney_client)

    %{conn | resp_headers: headers}
    # Delete the transfer encoding header. Ideally, we would read
    # if it is chunked or not and act accordingly to support streaming.
    # We may also need to delete other headers in a proxy.
    |> delete_resp_header("Transfer-Encoding")
    |> send_resp(status, body)
  end

  defp downstream_chunked_response(hackney_client) do
    {:ok, _hackney_client} = :hackney.start_response(hackney_client)
    await_async_response
  end

  # Be careful, this will receive all messages sent
  # like {:cowboy_req, :resp_sent}, {:plug_conn, :sent}
  # It will return the conn after the chunks have been sent
  def await_async_response do
    receive do
      {:async_done, conn} ->
        conn
      any_msg ->
        IO.inspect any_msg
        await_async_response
    end
  end

  # Not private function because it is called in another spawned process
  def async_response_handler(conn, target) do
    receive do
      {:hackney_response, _hackney_client, {:status, status_code, _reason_phrase}} ->
        Logger.info "Got status code #{status_code}"

        conn
        |> put_status(status_code)
        |> async_response_handler(target)
      {:hackney_response, _hackney_client, {:headers, headers}} ->
        Logger.info "Got headers"

        %{conn | resp_headers: headers}
        # PR: There should be a send_chunk that internally reads the status from the connection if it is already set
        |> send_chunked(conn.status)
        |> async_response_handler(target)
      {:hackney_response, _hackney_client, body_chunk} when is_binary(body_chunk) ->
        Logger.info "Got body chunk"

        Enum.into([body_chunk], conn)
        |> async_response_handler(target)
      {:hackney_response, _hackney_client, :done} ->
        Logger.info "Got everything!"

        send target, {:async_done, conn}
    end
  end

  defp extract_url(conn) do
    # TODO: Forward port
    # FIX: conn.request_path for https requests is like "yahoo.com:443"

    host = get_req_header conn, "host"
    base = to_string(conn.scheme) <> "://" <> conn.req_headers["host"] <> conn.request_path
    case conn.query_string do
      "" -> base
      query_string -> base <> "?" <> query_string
    end
  end

  defp extract_request_headers(conn) do
    # Remove Host header if requests are coming through a /endpoint
    # TODO: Add X-Forwarded-For ?? maybe as an option?
    conn
    |> delete_req_header("host")
    |> Map.get(:req_headers)
  end

  defp extract_response_headers(conn) do
  end
end
