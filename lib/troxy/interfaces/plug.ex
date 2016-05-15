defmodule Troxy.Interfaces.Plug do
  @moduledoc """
  A Plug to proxy requests to an upstream specified in the host header

  Based on Jose Valim's Proxy
  https://github.com/josevalim/proxy/blob/master/lib/proxy.ex

  ## Usage

  plug Troxy.Interfaces.Plug normalize_headers?: true
  """

  @behaviour Plug

  import Plug.Conn
  require IEx
  require Logger
  use Troxy.Interfaces.DefaultHandlers

  defmodule Error do
    defexception [:message]
  end

  defmacro __using__(opts) do
    quote location: :keep do
      # Default handler_module: __MODULE__
      plug Troxy.Interfaces.Plug, [{:handler_module, __MODULE__}, unquote_splicing(opts)]
      use Troxy.Interfaces.DefaultHandlers
    end
  end

  @spec init(Keyword.t) :: Keyword.t
  def init(opts) do
    opts
    |> add_default_option(:handler_module, __MODULE__)
    |> add_default_option(:normalize_headers?, true)
    |> add_default_option(:follow_redirects?, false)
    |> add_default_option(:stream?, true)
  end

  defp add_default_option(opts, key, value) do
    Keyword.update(opts, key, value, &(&1))
  end

  def call(conn = %Plug.Conn{private: %{plug_skip_troxy: true}}, _opts), do: conn
  def call(conn, opts) do
    Logger.debug ">>>"
    method = conn.method |> String.downcase |> String.to_atom
    url = extract_url(conn)
    headers = extract_request_headers(conn)

    Logger.debug "> #{method} #{url} #{inspect headers}"

    # Read response async
    # https://github.com/benoitc/hackney#get-a-response-asynchronously
    async_handler_task = Task.async(__MODULE__, :async_response_handler, [conn, opts])

    hackney_options = [
      {:follow_redirect, opts[:follow_redirects?]}, # Follow redirects
      {:max_redirect, 5},       # Default max redirects
      {:force_redirect, true},  # Force redirect even on POST
      :async,                   # Async response
      {:stream_to, async_handler_task.pid}, # Async PID handler
      :insecure                 # Ignore SSL cert validation
      # {:ssl_options, ssl_options} # Options for the SSL module
    ]

    # Streaming the upstream request payload
    # https://github.com/benoitc/hackney#send-the-body-by-yourself
    payload = :stream

    Logger.debug ">> #{method} #{url}"

    case :hackney.request(method, url, headers, payload, hackney_options) do
      {:ok, hackney_client} ->
        conn
        |> opts[:handler_module].req_handler
        |> upstream_chunked_request(opts, hackney_client)

        Logger.debug ">>> upstream complete"

        downstream_chunked_response(async_handler_task, hackney_client)
        |> Plug.Conn.halt
      {:error, cause} ->
        error_msg = inspect(cause)
        conn
        |> opts[:handler_module].req_handler
        |> opts[:handler_module].req_body_handler("", false)
        |> put_resp_header("x-troxy-error", error_msg)
        |> send_resp(500, error_msg)
        |> opts[:handler_module].resp_handler
        |> opts[:handler_module].resp_body_handler(error_msg, false)
        |> Plug.Conn.halt
    end

  end

  # Reads the original request body and writes it to the hackney client recursively
  defp upstream_chunked_request(conn, opts, hackney_client) do
    # Read a chunk of the request body
    # Plug.Conn.read_body for more info
    case read_body(conn) do
      {:more, body_chunk, conn} ->
        # There is still body to be read
        :hackney.send_body(hackney_client, body_chunk)

        conn
        |> opts[:handler_module].req_body_handler(body_chunk, true)
        |> upstream_chunked_request(opts, hackney_client)
      {:ok, body_chunk, conn} ->
        # The last part of the body has been read
        :hackney.send_body(hackney_client, body_chunk)
        conn
        |> opts[:handler_module].req_body_handler(body_chunk, false)
    end
  end

  # TODO: Use this to send response after all body is read
  defp send_response(conn, hackney_client) do
    # Missing case
    # {:error, :timeout}
    {:ok, status, headers, hackney_client} = :hackney.start_response(hackney_client)

    Logger.debug "<< #{status}"
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
    Logger.debug "< downstream started"
    Task.await(async_handler_task)
    # Task.await(async_handler_task, :infinity)
  end

  # Not private function because it is called in the async task
  @spec async_response_handler(Plug.Conn.t, Keyword.t) :: Plug.Conn.t
  def async_response_handler(conn, opts) do
    receive do
      {:hackney_response, _hackney_clients, {redirect, to_url, _headers}} when redirect in [:redirect, :see_other] ->
        Logger.debug "<<< redirect to #{to_url}"
        # TODO: Handle HTTPS redirects
        # TODO: Handle Retry-After headers
        # TODO: Handle remaining_redirects
        # TODO: Update request_path, path_info
        to_uri = URI.parse(to_url)

        Logger.debug(inspect to_uri)
        Logger.debug(inspect conn)
        conn
        |> Map.merge(%Plug.Conn{
              # TODO: fill path_info, scheme
              host: to_uri.host,
              request_path: to_uri.path,
              query_string: to_uri.query || ""}
              # Wondering why the Map.take??? - Plug.Conn has some defaults, so we don't want to override with them
              # TODO: improve this awful merge... I just don't know how to do:
              # %Plug.Conn{conn | host: to_uri.host ...} within a pipe |>
              |> Map.take([:host, :request_path, :query_string]))
        |> put_req_header("host", to_uri.authority)
        |> __MODULE__.call(opts)
        # conn
        # |> put_resp_headers(headers, opts[:normalize_headers?])
        # |> send_resp(303, "")
      {:hackney_response, _hackney_client, {:status, status_code, _reason_phrase}} ->
        Logger.debug "<< status code #{status_code}"
        conn
        |> put_status(status_code)
        |> async_response_handler(opts)
      {:hackney_response, _hackney_client, {:headers, headers}} ->
        Logger.debug "<< headers #{inspect headers}"
        conn
        |> put_resp_headers(headers, opts[:normalize_headers?])
        |> opts[:handler_module].resp_handler
        # PR: There should be a send_chunk that reads the status from conn if it is already set
        |> send_chunked(conn.status)
        |> async_response_handler(opts)
      {:hackney_response, _hackney_client, body_chunk} when is_binary(body_chunk) ->
        Logger.debug "<< body chunk"
        # Enum.into([body_chunk], conn)
        # TODO: Chunk after the handler, so the response can be modified
        {:ok, conn} = chunk(conn, body_chunk)
        conn
        |> opts[:handler_module].resp_body_handler(body_chunk, true)
        |> async_response_handler(opts)
      {:hackney_response, _hackney_client, :done} ->
        Logger.debug "<< done chunking!"

        conn
        |> opts[:handler_module].resp_body_handler("", false)
      {:hackney_response, _hackney_client, {:error, {:closed, reason}}} ->
        Logger.error "Connection closed. Reason: #{reason}"
        conn
      unexpected ->
        raise unexpected
    end
  end

  defp extract_url(conn) do
    # TODO: fix conn.request_path for https requests is like "yahoo.com:443"
    host = Plug.Conn.get_req_header(conn, "host") |> List.first
    if host == nil, do: raise(Error, "missing request host header")

    # Implement String.Chars protocol for URI
    # %URI{
    #   host: conn.req_headers["host"],
    # }

    # TODO: Remove this...
    port = case conn.scheme do
       http when http in [:http, :https] -> to_string(Application.get_env(:troxy, http)[:port])
    end

    case host do
      "localhost:" <> ^port ->
        raise(Error, "upstream: can't proxy itself")
      _ ->
        base = to_string(conn.scheme) <> "://" <> host <> conn.request_path
        case conn.query_string do
            "" -> base
            query_string -> base <> "?" <> query_string
        end
    end
  end

  defp extract_request_headers(conn) do
    # Remove Host header if requests are coming through a /endpoint
    # TODO: Add X-Forwarded-For ?? maybe as an option?
    conn
    |> delete_req_header("host")
    |> delete_req_header("cache-control") # Added by Plug?
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
  defp put_normalized_resp_headers(conn, [{header, value} | remaining_headers]) do
    conn
    |> put_resp_header(String.downcase(header), value)
    |> put_normalized_resp_headers(remaining_headers)
  end

  @spec put_raw_resp_headers(Plug.Conn.t, [{String.t, String.t}]) :: Plug.Conn.t
  defp put_raw_resp_headers(conn, headers) do
    %{conn | resp_headers: headers}
  end
end
