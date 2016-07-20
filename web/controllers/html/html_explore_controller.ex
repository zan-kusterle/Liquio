defmodule Democracy.HtmlExploreController do
	use Democracy.Web, :controller

	def index(conn, _) do
		conn
		|> render "index.html",
			heading: "List of all polls",
			polls: Poll.all |> Repo.all
	end

	def show(conn, %{"id" => topic}) do
		conn
		|> render "index.html",
			heading: "Polls with topic #{topic}",
			polls: Poll.by_topic(topic |> String.downcase) |> Repo.all
	end

	def search(conn, %{"query" => query}) do
		conn
		|> render "index.html",
			heading: "Showing most relevant polls",
			query: query,
			polls: Poll.search(Poll, query) |> Repo.all
	end
end