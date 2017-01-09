defmodule Liquio.HtmlPollController do
	use Liquio.Web, :controller
	alias Liquio.Helpers.PollHelper

	with_params(%{
		:node => {Plugs.NodeParam, [name: "id"]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
		:user => {Plugs.CurrentUser, [require: false]}
	},
	def show(conn, params = %{:node => node, :datetime => datetime, :user => user}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("show.html",
			title: node.title,
			calculation_opts: calculation_opts,
			datetime: datetime,
			poll: Node.preload(node, calculation_opts, user))
	end)

	plug :put_layout, "minimal.html" when action in [:embed]
	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id", validator: &Poll.is_custom/1]},
		:trust_metric_url => {Plugs.StringParam, [name: "trust_metric_url", maybe: true]},
	},
	def embed(conn, %{:poll => poll}) do
		calculation_opts = get_calculation_opts_from_conn(conn)

		conn
		|> render("embed.html",
			poll: PollHelper.prepare(poll, calculation_opts, nil, put_references: true))
	end)
end