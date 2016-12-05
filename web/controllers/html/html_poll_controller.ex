defmodule Liquio.HtmlPollController do
	use Liquio.Web, :controller

	def new(conn, _) do
		conn
		|> render("new.html")
	end

	with_params(%{
		:title => {Plugs.StringParam, [name: "title"]},
		:topics => {Plugs.ListParam, [name: "topics", maybe: true, item: {Plugs.StringParam, [downcase: true]}]},
		:choice_type => {Plugs.EnumParam, [name: "choice_type", values: ["probability", "quantity", "time_quantity"]]}
	},
	def create(conn, %{:title => title, :topics => topics, :choice_type => choice_type}) do
		poll = Poll.create(choice_type, title, topics)
		conn
		|> put_flash(:info, "Done, share the url so others can vote")
		|> redirect(to: html_poll_path(conn, :show, poll.id))
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
	def show(conn, %{:poll => poll, :datetime => datetime, :user => user}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		poll = prepare_poll(poll, calculation_opts)
		own_vote = if user do Vote.current_by(poll, user) else nil end
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("show.html",
			title: poll.title,
			poll: poll,
			contributions: prepare_contributions(poll, calculation_opts),
			own_vote: own_vote,
			own_poll: poll |> Map.put(:results, if own_vote do Poll.results_for_vote(poll, own_vote) else nil end),
			datetime: datetime,
			references: prepare_references(poll, calculation_opts),
			inverse_references: Reference.inverse_for_poll(poll, calculation_opts),
			calculation_opts: calculation_opts)
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
			poll: prepare_poll(poll, calculation_opts),
			references: prepare_references(poll, calculation_opts))
	end)

	defp prepare_poll(poll, calculation_opts) do
		poll
		|> Map.put(:results, Poll.calculate(poll, calculation_opts))
	end

	defp prepare_references(poll, calculation_opts) do
		Reference.for_poll(poll, calculation_opts)
	end

	defp prepare_contributions(poll, calculation_opts) do
		poll |> Poll.calculate_contributions(calculation_opts) |> Enum.map(fn(contribution) ->
			Map.put(contribution, :identity, Repo.get(Identity, contribution.identity_id))
		end)
	end
end