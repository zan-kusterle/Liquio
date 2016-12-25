defmodule Liquio.HtmlExploreController do
	use Liquio.Web, :controller
	alias Liquio.Helpers.PollHelper

	def index(conn, %{"sort" => sort}) do
		polls = Poll |> Poll.sorted_for_keyword(sort) |> Repo.all
		|> Enum.map(& PollHelper.prepare(&1, nil, nil, from_default_cache: true))
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
			polls = Poll |> Poll.by_default_topic(topic |> String.downcase) |> Poll.sorted_for_keyword(sort) |> Repo.all
			|> Enum.map(& PollHelper.prepare(&1, nil, nil, from_default_cache: true))

			conn
			|> render("index.html",
				heading: "POLLS WITH TOPIC #{topic |> String.upcase}",
				url: "/topics/#{topic |> String.downcase}",
				sort: sort,
				polls: polls,
				topic_name: topic,
				identities: [])
		end
	end

	def show_embed(conn, %{"html_explore_id" => topic, "sort" => sort}) do
		polls = Poll |> Poll.by_default_topic(topic |> String.downcase) |> Poll.sorted_for_keyword(sort) |> Repo.all
		|> Enum.map(& PollHelper.prepare(&1, nil, nil, from_default_cache: true))

		conn
		|> put_layout("raw.html")
		|> render("embed.html",
			polls: polls,
			identities: [])
	end

	def search(conn, %{"query" => query}) do
		polls = Poll |> Poll.search(query) |> Repo.all
		|> Enum.map(& PollHelper.prepare(&1, nil, nil, from_default_cache: true))

		conn
		|> render("index.html",
			heading: "RESULTS",
			query: query,
			polls: polls,
			identities: Identity |> Identity.search(query) |> Repo.all)
	end
end