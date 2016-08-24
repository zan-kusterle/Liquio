defmodule Liquio.HtmlExploreController do
	use Liquio.Web, :controller

	def index(conn, _) do
		conn
		|> render("index.html",
			heading: "ALL POLLS",
			polls: Poll.all |> Repo.all)
	end

	def show(conn, %{"id" => topic}) do
		topic_downcase = topic |> String.downcase
		conn
		|> render("index.html",
			heading: "POLLS WITH TOPIC #{topic |> String.upcase}",
			polls: topic_downcase |> Poll.by_topic |> Repo.all)
	end

	def search(conn, %{"query" => query, "t" => type}) do
		if type == "identity" do
			conn
			|> render("identities.html",
				heading: "SHOWING MOST RELEVANT IDENTITIES",
				query: query,
				identities: Identity |> Identity.search(query) |> Repo.all)
		else
			conn
			|> render("index.html",
				heading: "SHOWING MOST RELEVANT POLLS",
				query: query,
				polls: Poll |> Poll.search(query) |> Repo.all)
		end
	end
end