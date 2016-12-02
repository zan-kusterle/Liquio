defmodule Liquio.HtmlExploreController do
	use Liquio.Web, :controller

	def index(conn, %{"sort" => sort}) do
		conn
		|> render("index.html",
			heading: "ALL POLLS",
			url: "/explore",
			polls: Poll.all |> Repo.all,
			identities: [])
	end

	def show(conn, %{"html_explore_id" => topic, "sort" => sort}) do
		conn
		|> render("index.html",
			heading: "POLLS WITH TOPIC #{topic |> String.upcase}",
			url: "/topics/#{topic |> String.downcase}",
			polls: topic |> String.downcase |> Poll.by_topic |> Repo.all,
			identities: [])
	end

	def search(conn, %{"query" => query, "sort" => sort}) do
		conn
		|> render("index.html",
			heading: "RESULTS",
			url: "/search",
			query: query,
			polls: Poll |> Poll.search(query) |> Repo.all,
			identities: Identity |> Identity.search(query) |> Repo.all)
	end
end