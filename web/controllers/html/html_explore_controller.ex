defmodule Democracy.HtmlExploreController do
	use Democracy.Web, :controller

	def index(conn, _params) do
		conn
		|> render "index.html"
	end
end