defmodule LiquioWeb.RedirectWwwPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.host |> String.starts_with?("www.") do
      port =
        if conn.port != 80 and conn.port != 443 do
          ":#{conn.port}"
        else
          ""
        end

      query =
        if String.length(Map.get(conn, :query_string, "")) > 0 do
          "?#{conn.query_string}"
        else
          ""
        end

      url =
        to_string(conn.scheme) <>
          "://" <> String.trim_leading(conn.host, "www.") <> port <> conn.request_path <> query

      conn
      |> Phoenix.Controller.redirect(external: url)
      |> halt
    else
      conn
    end
  end
end

defmodule LiquioWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :liquio

  plug(
    Plug.Static,
    at: "/",
    from: :liquio,
    gzip: true,
    only: ~w(privacy.txt robots.txt promo)
  )

  plug(
    Plug.Static,
    at: "/",
    from: "/etc/letsencrypt/static",
    gzip: false,
    only: ~w(.well-known)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(LiquioWeb.RedirectWwwPlug)

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  plug(CORSPlug, origin: "*")

  plug(LiquioWeb.Router)
end
