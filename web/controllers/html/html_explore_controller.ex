defmodule Democracy.HtmlExploreController do
	use Democracy.Web, :controller

	def index(conn, _) do
		polls = Poll.all |> Repo.all
		conn
		|> render "index.html", polls: polls
	end

	def show(conn, %{"id" => topic}) do
		polls = Poll.by_topic(topic |> String.downcase) |> Repo.all
		conn
		|> render "index.html", polls: polls
	end

	def search(conn, %{"query" => query}) do
		polls = Poll.search(Poll, query) |> Repo.all
		conn
		|> render "index.html", polls: polls, query: query
	end
end