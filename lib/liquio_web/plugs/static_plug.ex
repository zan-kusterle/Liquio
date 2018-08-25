defmodule LiquioWeb.Plugs.StaticPlug do
    @behaviour Plug
    import Plug.Conn

    def init(opts), do: opts

    def call(conn, _opts) do
        if Mix.env() == :dev and conn.request_path == "/dev" do
            send_file(conn, 200, Application.app_dir(:liquio, "priv/static/index.html"))
        else
            send_file(conn, 200, Application.app_dir(:liquio, "priv/static/promo/index.html"))
        end
    end
end
