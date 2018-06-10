defmodule LiquioWeb.IndexController do
  use LiquioWeb, :controller

  def index(conn, _) do
    conn
    |> put_resp_header("Cache-Control", "public, max-age=864000")
    |> render(LiquioWeb.LayoutView)
  end
end
