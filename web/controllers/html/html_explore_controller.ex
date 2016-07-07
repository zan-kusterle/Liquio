defmodule Democracy.HtmlExploreController do
	use Democracy.Web, :controller

	alias Democracy.Poll

	def index(conn, _params) do
		polls = Poll.all |> Repo.all
		conn
		|> render "index.html", polls: polls
	end
end