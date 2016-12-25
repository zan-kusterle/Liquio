defmodule Liquio.HtmlTopicController do
	use Liquio.Web, :controller

	alias Liquio.Helpers.PollHelper

	with_params(%{
		:user => {Plugs.CurrentUser, [require: false]},
		:poll => {Plugs.ItemParam, [schema: Poll, name: "poll_id", validator: &Poll.is_custom/1]},
	},
	def reference(conn, %{"html_explore_id" => topic_name, :poll => poll, :user => user}) do
		topic = Topic.get(topic_name, poll) |> Repo.preload([:relevance_poll])
		calculation_opts = get_calculation_opts_from_conn(conn)

		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("show_reference.html",
			title: poll.title || "Liquio",
			calculation_opts: calculation_opts,
			topic_name: topic.name,
			poll: PollHelper.prepare(poll, calculation_opts, user),
			relevance_poll: PollHelper.prepare(topic.relevance_poll, calculation_opts, user))
	end)
end