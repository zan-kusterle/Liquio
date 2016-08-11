defmodule Liquio.HtmlPollController do
	use Liquio.Web, :controller

	def new(conn, _) do
		conn
		|> render "new.html"
	end

	with_params(%{
		:title => {Plugs.StringParam, [name: "title"]},
		:topics => {Plugs.ListParam, [name: "topics", maybe: true, item: {Plugs.StringParam, [downcase: true]}]},
		:choice_type => {Plugs.EnumParam, [name: "choice_type", values: ["probability", "quantity"]]},
	},
	def create(conn, %{:title => title, :topics => topics, :choice_type => choice_type}) do
		poll = Poll.create(choice_type, title, topics)
		conn
		|> put_flash(:info, "Done, share the url so others can vote")
		|> redirect to: html_poll_path(conn, :show, poll.id)
	end)

	def show(conn, %{"id" => "random"}) do
		conn
		|> redirect to: html_poll_path(conn, :show, Poll.get_random().id)
	end

	with_params(%{
		:user => {Plugs.CurrentUser, [require: false]},
		:poll => {Plugs.ItemParam, [schema: Poll, name: "id", validator: &Poll.is_custom/1]},
	},
	def show(conn, %{:user => user, :poll => poll}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		poll = prepare_poll(poll, calculation_opts)
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "show.html",
			title: poll.title,
			is_logged_in: user != nil,
			poll: poll,
			references: prepare_references(poll, calculation_opts),
			inverse_references: Reference.inverse_for_poll(poll, calculation_opts),
			is_above_minimum_voting_power: poll.results.total >= calculation_opts[:minimum_voting_power]
	end)

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id", validator: &Poll.is_custom/1]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
	},
	def details(conn, %{:poll => poll, :datetime => datetime}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "details.html",
			title: poll.title,
			datetime_text: Timex.format!(datetime, "{ISOdate}"),
			poll: prepare_poll(poll, calculation_opts),
			contributions: prepare_contributions(poll, calculation_opts),
			results_with_datetime: prepare_results_with_datetime(poll, 30, calculation_opts)
	end)

	plug :put_layout, "minimal.html" when action in [:embed]
	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id", validator: &Poll.is_custom/1]},
		:trust_metric_url => {Plugs.StringParam, [name: "trust_metric_url", maybe: true]},
	},
	def embed(conn, %{:poll => poll}) do
		calculation_opts = get_calculation_opts_from_conn(conn)

		conn
		|> render "embed.html",
			poll: prepare_poll(poll, calculation_opts),
			references: prepare_references(poll, calculation_opts)
	end)

	defp prepare_poll(poll, calculate_opts) do
		poll
		|> Map.put(:results, Result.calculate(poll, calculate_opts))
	end

	defp prepare_references(poll, calculate_opts) do
		Reference.for_poll(poll, calculate_opts)
	end

	defp prepare_contributions(poll, calculate_opts) do
		Result.calculate_contributions(poll, calculate_opts) |> Enum.map(fn(contribution) ->
			Map.put(contribution, :identity, Repo.get(Identity, contribution.identity_id))
		end)
	end

	defp prepare_results_with_datetime(poll, num_units, calculate_opts) do
		Enum.map(0..num_units, fn(shift_units) ->
			datetime = Timex.shift(calculate_opts[:datetime], days: -shift_units)
			{
				num_units - shift_units,
				datetime,
				Result.calculate(poll, calculate_opts)
			}
		end)
	end
end