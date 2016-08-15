defmodule Liquio.HtmlExploreController do
	use Liquio.Web, :controller

	def index(conn, _) do
		conn
		|> render("index.html",
			heading: "ALL POLLS",
			polls: Poll.all |> Repo.all)
	end

	def show(conn, %{"id" => topic}) do
		conn
		|> render("index.html",
			heading: "POLLS WITH TOPIC #{topic |> String.upcase}",
			polls: Poll.by_topic(topic |> String.downcase) |> Repo.all)
	end

	def search(conn, %{"query" => query}) do
		conn
		|> render("index.html",
			heading: "SHOWING MOST RELEVANT POLLS",
			query: query,
			polls: Poll.search(Poll, query) |> Repo.all)
	end
end