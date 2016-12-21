defmodule Liquio.HtmlTopicController do
	use Liquio.Web, :controller

	alias Liquio.Topic

	with_params(%{
		:user => {Plugs.CurrentUser, [require: false]},
		:poll => {Plugs.ItemParam, [schema: Poll, name: "poll_id", validator: &Poll.is_custom/1]},
	},
	def reference(conn, %{"html_explore_id" => topic_name, :poll => poll, :user => user}) do
		topic = Topic.get(topic_name, poll) |> Repo.preload([:relevance_poll])
		calculation_opts = get_calculation_opts_from_conn(conn)
		poll = poll
		|> Map.put(:results, Poll.calculate(poll, calculation_opts))
		|> Map.put(:topics, Topic.for_poll(poll, calculation_opts) |> Topic.filter_visible)
		relevance_poll = topic.relevance_poll
		|> Map.put(:own_vote, if user do Vote.current_by(topic.relevance_poll, user) else nil end)
		|> Map.put(:contributions, Poll.calculate_contributions(topic.relevance_poll, calculation_opts))
		|> Map.put(:results, Poll.calculate(topic.relevance_poll, calculation_opts))
		topic = topic |> Map.put(:poll, poll) |> Map.put(:relevance_poll, relevance_poll)

		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("show_reference.html",
			title: poll.title || "Liquio",
			poll: poll |> Map.put(:results, Poll.calculate(poll, calculation_opts)),
			reference: topic,
			calculation_opts: calculation_opts
		)
	end)
end