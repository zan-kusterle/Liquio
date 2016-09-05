defmodule Liquio.HtmlPollController do
	use Liquio.Web, :controller

	def new(conn, _) do
		conn
		|> render("new.html")
	end

	with_params(%{
		:title => {Plugs.StringParam, [name: "title"]},
		:topics => {Plugs.ListParam, [name: "topics", maybe: true, item: {Plugs.StringParam, [downcase: true]}]},
		:choice_type => {Plugs.EnumParam, [name: "choice_type", values: ["probability", "quantity", "time_quantity"]]},
		:choice_unit => {Plugs.StringParam, [name: "choice_unit", maybe: true]},
		:time_unit => {Plugs.EnumParam, [name: "time_unit", maybe: true, values: ["year", "month", "week", "day"]]},
		:is_choice_time_difference => {Plugs.BooleanParam, [name: "is_choice_time_difference"]},
	},
	def create(conn, %{:title => title, :topics => topics, :choice_type => choice_type, :choice_unit => choice_unit, :time_unit => time_unit, :is_choice_time_difference => is_choice_time_difference}) do
		poll = Poll.create(choice_type, title, topics, choice_unit, time_unit, is_choice_time_difference)
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
	},
	def show(conn, %{:poll => poll}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		poll = prepare_poll(poll, calculation_opts)
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("show.html",
			title: poll.title,
			poll: poll,
			references: prepare_references(poll, calculation_opts),
			inverse_references: Reference.inverse_for_poll(poll, calculation_opts),
			minimum_voting_power: calculation_opts[:minimum_voting_power])
	end)

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id", validator: &Poll.is_custom/1]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
	},
	def details(conn, %{:poll => poll, :datetime => datetime}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("details.html",
			title: poll.title,
			datetime_text: Timex.format!(datetime, "{ISOdate}"),
			poll: prepare_poll(poll, calculation_opts),
			contributions: prepare_contributions(poll, calculation_opts),
			chart_points: prepare_chart_points(poll, 30, calculation_opts))
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

	defp prepare_poll(poll, calculate_opts) do
		poll
		|> Map.put(:results, Poll.calculate(poll, calculate_opts))
	end

	defp prepare_references(poll, calculate_opts) do
		Reference.for_poll(poll, calculate_opts)
	end

	defp prepare_contributions(poll, calculate_opts) do
		poll |> Poll.calculate_contributions(calculate_opts) |> Enum.map(fn(contribution) ->
			Map.put(contribution, :identity, Repo.get(Identity, contribution.identity_id))
		end)
	end

	defp prepare_chart_points(poll, num_units, calculate_opts) do
		results_with_datetime = Enum.map(0..num_units, fn(shift_units) ->
			datetime = Timex.shift(calculate_opts[:datetime], days: -shift_units)
			{
				num_units - shift_units,
				datetime,
				Poll.calculate(poll, Map.put(calculate_opts, :datetime, datetime))
			}
		end)

		count = Enum.count(results_with_datetime)
		means = results_with_datetime
		|> Enum.map(fn({_index, _datetime, results}) -> results.mean end)
		|> Enum.filter(& &1 != nil)
		max_mean = if Enum.empty?(means) do
			1
		else
			Enum.max([1, Enum.max(means)])
		end
		points = Enum.map(results_with_datetime, fn({index, _datetime, results}) ->
			if results.mean do
				{index / (count - 1), results.mean / max_mean}
			else
				nil
			end
		end)
		|> Enum.filter(& &1 != nil)

		Enum.reverse(points)
	end
end