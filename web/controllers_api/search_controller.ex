defmodule Liquio.SearchController do
	use Liquio.Web, :controller

	def index(conn, %{"query" => query}) do
		polls = Poll |> Poll.search(query) |> Repo.all
		conn
		|> render("index.json", polls: polls)
	end
end