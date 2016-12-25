defmodule Liquio.HtmlPollController do
	use Liquio.Web, :controller
	alias Liquio.Helpers.PollHelper

	def new(conn, _) do
		conn
		|> render("new.html")
	end

	with_params(%{
		:title => {Plugs.StringParam, [name: "title"]},
		:choice_type => {Plugs.EnumParam, [name: "choice_type", values: ["probability", "quantity", "time_quantity"]]},
		:reference_to_poll => {Plugs.ItemParam, [schema: Poll, name: "reference_to_poll_id", maybe: true, validator: &Poll.is_custom/1]}
	},
	def create(conn, %{:title => title, :choice_type => choice_type, :reference_to_poll => reference_to_poll}) do
		poll = Poll.create(choice_type, title)

		if reference_to_poll != nil do
			conn
			|> put_flash(:info, "Done, you can add a reference now.")
			|> redirect(to: html_poll_html_reference_path(conn, :show, reference_to_poll.id, poll.id))
		else
			conn
			|> put_flash(:info, "Done, share the url so others can vote.")
			|> redirect(to: html_poll_path(conn, :show, poll.id))
		end
	end)

	def show(conn, %{"id" => "random"}) do
		conn
		|> redirect(to: html_poll_path(conn, :show, Poll.get_random().id))
	end

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "id", validator: &Poll.is_custom/1]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
		:user => {Plugs.CurrentUser, [require: false]}
	},
	def show(conn, params = %{:poll => poll, :datetime => datetime, :user => user}) do
		if Map.has_key?(params, "topic_name") do
			topic_name = params["topic_name"]

			if String.length(topic_name) > 0 do
				conn
				|> redirect(to: html_explore_html_topic_path(conn, :reference, topic_name, poll.id))
			else
				conn
				|> redirect(to: html_poll_path(conn, :show, poll.id))
			end
		else
			calculation_opts = get_calculation_opts_from_conn(conn)
			own_vote = if user do Vote.current_by(poll, user) else nil end
			conn
			|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
			|> render("show.html",
				title: poll.title,
				calculation_opts: calculation_opts,
				datetime: datetime,
				poll: PollHelper.prepare(poll, calculation_opts, user, put_references: true, put_inverse_references: true))
		end
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