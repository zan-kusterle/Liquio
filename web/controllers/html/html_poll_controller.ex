defmodule Democracy.HtmlPollController do
	use Democracy.Web, :controller

	def new(conn, _) do
		conn
		|> render "new.html"
	end

	with_params(%{
		:title => {Plugs.StringParam, [name: "title"]},
		:topics => {Plugs.ListParam, [name: "topics", item: {Plugs.StringParam, []}]},
		:choice_type => {Plugs.ChoiceTypeParam, [name: "choice_type", topics_name: :topics]},
	},
	def create(conn, %{:choice_type => choice_type, :title => title, :topics => topics}) do
		poll = Poll.create(choice_type, title, topics)
		conn
		|> put_flash(:info, "Done, share the url so others can vote")
		|> redirect to: html_poll_path(conn, :show, poll.id)
	end)

	def show(conn, %{"id" => "random"}) do
		conn
		|> redirect to: html_poll_path(conn, :show, Poll.get_random().id)
	end

	# TODO: I don't want user to pass datetime, vote_weight_halving_days or trust_metric_url.
	# That's why here I should remove those params and ensure get_calculation_opts_from_conn works flexible with any combination of params/preferences/defaults.
	# Also replace trust_metric_ids with trust_metric_url StringParam, since trust metric ids are generated in the function
	with_params(%{
		:user => {Plugs.CurrentUser, [require: false]},
		:poll => {Plugs.ItemParam, [schema: Poll, name: "id"]},
	},
	def show(conn, params = %{:user => user, :poll => poll}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "show.html",
			title: Poll.title(poll),
			is_logged_in: user != nil,
			poll: prepare_poll(poll, calculation_opts),
			references: prepare_references(poll, calculation_opts)
	end)

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id"]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
	},
	def details(conn, %{:poll => poll, :datetime => datetime}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "details.html",
			title: Poll.title(poll),
			datetime_text: Timex.format!(datetime, "{ISOdate}"),
			poll: prepare_poll(poll, calculation_opts),
			contributions: prepare_contributions(poll, calculation_opts),
			results_with_datetime: prepare_results_with_datetime(poll, 30, calculation_opts)
	end)

	plug :put_layout, "minimal.html" when action in [:embed]
	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id"]},
		:trust_metric_ids => {Plugs.TrustMetricIdsParam, [name: "trust_metric_url"]},
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
		|> Map.put(:title, Poll.title(poll))
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