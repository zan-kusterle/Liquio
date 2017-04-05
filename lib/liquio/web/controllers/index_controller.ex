defmodule Liquio.Web.IndexController do
	use Liquio.Web, :controller

	def app(conn, _) do
		conn
		|> put_resp_header("Cache-Control", "public, max-age=864000")
		|> render(Liquio.Web.LayoutView)
	end

	def link(conn, _) do
		conn
		|> render(Liquio.Web.LayoutView, layout: {Liquio.Web.LayoutView, "link.html"})
	end
end