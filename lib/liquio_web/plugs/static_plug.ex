defmodule LiquioWeb.Plugs.StaticPlug do
    @behaviour Plug
    import Plug.Conn

    def init(opts), do: opts

    def call(conn, _opts), do: send_file(conn, 200, Application.app_dir(:liquio, "priv/static/promo/index.html"))
end
