defmodule Democracy.HtmlIdentityController do
	use Democracy.Web, :controller

	alias Democracy.Identity

	plug Democracy.Plugs.QueryId, {:identity, Identity, "id"} when action in [:show]

	def show(conn, _params) do
		conn
		|> render "index.html", identity: conn.assigns.identity
	end
end