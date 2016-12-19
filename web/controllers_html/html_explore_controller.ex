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

	def show(conn, params = %{"html_explore_id" => topic, "sort" => sort}) do
		if Map.has_key?(params, "poll_url") do
			poll_url = params["poll_url"]
			url = URI.parse(poll_url)
			poll_id =
				if url.path != nil and url.path |> String.starts_with?("/polls/") do
					String.replace(url.path, "/polls/", "")
				else
					poll_url
				end
			poll = if String.length(poll_id) == 0 do nil else Repo.get(Poll, poll_id) end

			if poll != nil and poll.kind == "custom" do
				conn
				|> redirect(to: html_explore_html_topic_path(conn, :reference, topic, poll.id))
			else
				conn
				|> put_flash(:info, "The poll you want to reference does not exist.")
				|> redirect(to: html_explore_html_explore_path(conn, :show, topic, sort))
			end
		else
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