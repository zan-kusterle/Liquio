defmodule Liquio.HtmlTopicController do
	use Liquio.Web, :controller
	alias Liquio.Helpers.PollHelper

	def show(conn, params = %{"path" => topic, "sort" => sort}) do
		topic_path = String.split(String.downcase(topic), ">") |> Enum.map(& String.trim(&1)) |> Enum.filter(& String.length(&1) > 0)
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
				|> redirect(to: html_topic_path(conn, :reference, topic, poll.id))
			else
				conn
				|> put_flash(:info, "The poll you want to reference does not exist.")
				|> redirect(to: html_topic_path(conn, :show, topic, sort))
			end
		else
			polls = Poll |> Poll.by_default_topic(topic_path) |> Poll.sorted_for_keyword(sort) |> Repo.all
			|> Enum.map(& PollHelper.prepare(&1, nil, nil, from_default_cache: true))

			conn
			|> render(Liquio.HtmlExploreView, "index.html",
				heading: "TOPIC",
				url: "/topics/#{topic}",
				sort: sort,
				polls: polls,
				topic_path: topic_path,
				identities: [])
		end
	end

	def show_embed(conn, %{"path" => path_text, "sort" => sort}) do
		path = String.split(String.downcase(path_text), ">") |> Enum.map(& String.trim(&1)) |> Enum.filter(& String.length(&1) > 0)
		polls = Poll |> Poll.by_default_topic(path) |> Poll.sorted_for_keyword(sort) |> Repo.all
		|> Enum.map(& PollHelper.prepare(&1, nil, nil, from_default_cache: true))

		conn
		|> put_layout("raw.html")
		|> render(Liquio.HtmlExploreView, "embed.html",
			polls: polls,
			identities: [])
	end

	with_params(%{
		:user => {Plugs.CurrentUser, [require: false]},
		:poll => {Plugs.ItemParam, [schema: Poll, name: "poll_id", validator: &Poll.is_custom/1]},
	},
	def reference(conn, %{"path" => topic_name, :poll => poll, :user => user}) do
		topic_path = String.split(String.downcase(topic_name), ">") |> Enum.map(& String.trim(&1)) |> Enum.filter(& String.length(&1) > 0)
		topic = TopicReference.get(topic_path, poll) |> Repo.preload([:relevance_poll])
		calculation_opts = get_calculation_opts_from_conn(conn)

		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("show_reference.html",
			title: poll.title || "Liquio",
			calculation_opts: calculation_opts,
			topic_path: topic.path,
			poll: PollHelper.prepare(poll, calculation_opts, user),
			relevance_poll: PollHelper.prepare(topic.relevance_poll, calculation_opts, user))
	end)
end