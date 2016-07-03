defmodule Democracy.SearchController do
	use Democracy.Web, :controller

	alias Democracy.Poll

	def index(conn, %{"query" => query}) do
		polls = Poll |> Poll.search(query) |> Repo.all
		conn
		|> render("index.json", polls: polls)
	end
end