defmodule Liquio.SearchController do
	use Liquio.Web, :controller

	alias Liquio.Poll

	def index(conn, %{"query" => query}) do
		polls = Poll |> Poll.search(query) |> Repo.all
		conn
		|> render("index.json", polls: polls)
	end
end