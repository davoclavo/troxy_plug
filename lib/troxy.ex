defmodule Troxy do
  @moduledoc """
  A Plug to proxy requests to an upstream specified in the host header

  Based on Jose Valim's Proxy
  https://github.com/josevalim/proxy/blob/master/lib/proxy.ex

  ## Usage

      plug Troxy, upstream_handler: &__MODULE__.upstream_handler/1,
                  downstream_handler: &__MODULE__.downstream_handler/1,
                  normalize_headers?: true
  """

  @behaviour Plug

  import Plug.Conn
  require IEx
  require Logger

  def init(opts) do
    upstream_handler = Keyword.get(opts, :upstream_handler, &(&1))
    downstream_handler = Keyword.get(opts, :downstream_handler, &(&1))
    normalize_headers? = Keyword.get(opts, :normalize_headers?, false)

    {upstream_handler, downstream_handler, normalize_headers?}
  end

  def call(conn, {upstream_handler, downstream_handler, normalize_headers?}) do
    method = conn.method |> String.downcase |> String.to_atom
    url = extract_url(conn)
    headers = extract_request_headers(conn)

    # TODO: Return an error if url is the same as the proxy

    Logger.info "> #{method} #{url} #{inspect headers}"

    # Read response async
    # https://github.com/benoitc/hackney#get-a-response-asynchronously

    async_handler_task = Task.async __MODULE__, :async_response_handler, [conn, normalize_headers?]

    hackney_options = [
      {:follow_redirect, true}, # Follow redirects
      {:force_redirect, true},  # Force redirect even on POST
      :async,                   # Async response
      {:stream_to, async_handler_task.pid} # Async PID handler
    # :insecure                 # Ignore SSL cert validation
    ]

    # Streaming the upstream request body
    body = :stream

    {:ok, hackney_client} = :hackney.request(method, url, headers, body, hackney_options)
    Logger.info ">> #{method} #{url}"

    conn
    |> upstream_handler.()
    |> upstream_chunked_request(hackney_client)

    downstream_chunked_response(async_handler_task, hackney_client)
    |> downstream_handler.()
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

  defp downstream_chunked_response(async_handler_task, hackney_client) do
    {:ok, _hackney_client} = :hackney.start_response(hackney_client)
    Task.await async_handler_task, :infinity
  end

  @spec async_response_handler(Plug.Conn.t, boolean) :: Plug.Conn.t
  # Not private function because it is called in the async task
  def async_response_handler(conn, normalize_headers?) do
    receive do
      {:hackney_response, _hackney_client, {:status, status_code, _reason_phrase}} ->
        Logger.info "Got status code #{status_code}"

        conn
        |> put_status(status_code)
        |> async_response_handler(normalize_headers?)
      {:hackney_response, _hackney_client, {:headers, headers}} ->
        Logger.info "Got headers #{inspect headers}"

        conn
        |> put_resp_headers(headers, normalize_headers?)
        # PR: There should be a send_chunk that internally reads the status from the connection if it is already set
        |> send_chunked(conn.status)
        |> async_response_handler(normalize_headers?)
      {:hackney_response, _hackney_client, body_chunk} when is_binary(body_chunk) ->
        Logger.info "Got body chunk"

        # Enum.into([body_chunk], conn)
        {:ok, conn} = chunk(conn, body_chunk)

        conn
        |> async_response_handler(normalize_headers?)
      {:hackney_response, _hackney_client, :done} ->
        Logger.info "Got everything!"

        conn
    end
  end

  defp extract_url(conn) do
    # TODO: Forward port
    # FIX: conn.request_path for https requests is like "yahoo.com:443"
    host = conn.req_headers["host"]
    # raise "has to have an upstream host"

    base = to_string(conn.scheme) <> "://" <> host <> conn.request_path
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

  @spec put_resp_headers(Plug.Conn.t, [{String.t, String.t}], boolean) :: Plug.Conn.t
  defp put_resp_headers(conn, headers, normalize_headers?) do
    if normalize_headers? do
      put_normalized_resp_headers(conn, headers)
    else
      # Don't downcase them (maybe the client relies on the original casing)
      put_raw_resp_headers(conn, headers)
    end
  end

  defp put_normalized_resp_headers(conn, []), do: conn
  defp put_normalized_resp_headers(conn, [{header, value}|remaining_headers]) do
    conn
    |> put_resp_header(String.downcase(header), value)
    |> put_normalized_resp_headers remaining_headers
  end

  @spec put_raw_resp_headers(Plug.Conn.t, [{String.t, String.t}]) :: Plug.Conn.t
  defp put_raw_resp_headers(conn, headers) do
    %{conn | resp_headers: headers}
  end

end
