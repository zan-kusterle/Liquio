defmodule Liquio.HtmlExploreController do
	use Liquio.Web, :controller

	def index(conn, %{"sort" => sort}) do
		polls = case sort do
			"new" -> Poll |> Poll.sorted_new |> Repo.all
			"top" -> Poll |> Poll.sorted_top |> Repo.all
			"most-certain" -> Poll |> Poll.sorted_certain |> Repo.all
			"least-certain" -> Poll |> Poll.sorted_certain |> Repo.all |> Enum.reverse
		end
		conn
		|> render("index.html",
			heading: "ALL POLLS",
			url: "/explore",
			sort: sort,
			polls: polls,
			identities: [])
	end

	def show(conn, %{"html_explore_id" => topic, "sort" => sort}) do
		polls = case sort do
			"new" -> Poll |> Poll.by_default_topic(topic |> String.downcase) |> Poll.sorted_new |> Repo.all
			"top" -> Poll |> Poll.by_default_topic(topic |> String.downcase) |> Poll.sorted_top |> Repo.all
			"most-certain" -> Poll |> Poll.by_default_topic(topic |> String.downcase) |> Poll.sorted_certain |> Repo.all
			"least-certain" -> Poll |> Poll.by_default_topic(topic |> String.downcase) |> Poll.sorted_certain |> Repo.all |> Enum.reverse
		end
		conn
		|> render("index.html",
			heading: "POLLS WITH TOPIC #{topic |> String.upcase}",
			url: "/topics/#{topic |> String.downcase}",
			sort: sort,
			polls: polls,
			identities: [])
	end

	def show_embed(conn, %{"html_explore_id" => topic, "sort" => sort}) do
		polls = case sort do
			"new" -> Poll |> Poll.by_default_topic(topic |> String.downcase) |> Poll.sorted_new |> Repo.all
			"top" -> Poll |> Poll.by_default_topic(topic |> String.downcase) |> Poll.sorted_top |> Repo.all
			"most-certain" -> Poll |> Poll.by_default_topic(topic |> String.downcase) |> Poll.sorted_certain |> Repo.all
			"least-certain" -> Poll |> Poll.by_default_topic(topic |> String.downcase) |> Poll.sorted_certain |> Repo.all |> Enum.reverse
		end
		conn
		|> put_layout("raw.html")
		|> render("embed.html",
			polls: polls,
			identities: [])
	end

	def search(conn, %{"query" => query}) do
		conn
		|> render("index.html",
			heading: "RESULTS",
			query: query,
			polls: Poll |> Poll.search(query) |> Repo.all,
			identities: Identity |> Identity.search(query) |> Repo.all)
	end
end