defmodule Democracy.HtmlExploreController do
	use Democracy.Web, :controller

	alias Democracy.Poll

	def index(conn, _params) do
		polls = Poll.all |> Repo.all
		conn
		|> render "index.html", polls: polls
	end

	def search(conn, %{"query" => query}) do
		polls = Poll.search(Poll, query) |> Repo.all
		conn
		|> render "index.html", polls: polls, query: query
	end
end