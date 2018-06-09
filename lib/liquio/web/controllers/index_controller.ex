defmodule Liquio.Web.IndexController do
  use Liquio.Web, :controller

  def index(conn, _) do
    conn
    |> put_resp_header("Cache-Control", "public, max-age=864000")
    |> render(Liquio.Web.LayoutView)
  end
end
