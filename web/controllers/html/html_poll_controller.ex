defmodule Democracy.HtmlPollController do
	use Democracy.Web, :controller

	def new(conn, _) do
		conn
		|> render "new.html"
	end

	with_params(%{
		:choice_type => {Plugs.ChoiceTypeParam, [name: "choice_type", topics_name: :topics]},
		:title => {Plugs.StringParam, [name: "title"]},
		:topics => {Plugs.ListParam, [name: "topics", item: {Plugs.StringParam, []}]}
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

	with_params(%{
		:user => {Plugs.CurrentUser, [require: false]},
		:poll => {Plugs.ItemParam, [schema: Poll, name: "id"]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
		:vote_weight_halving_days => {Plugs.IntegerParam, [name: "vote_weight_halving_days"]},
		:trust_metric_ids => {Plugs.TrustMetricIdsParam, [name: "trust_metric_url"]},
	},
	def show(conn, params = %{:user => user, :poll => poll, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "show.html",
			title: Poll.title(poll),
			is_logged_in: user != nil,
			poll: prepare_poll(poll, params),
			references: Reference.for_poll(poll, datetime, vote_weight_halving_days, trust_metric_ids)
	end)

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id"]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
		:vote_weight_halving_days => {Plugs.IntegerParam, [name: "vote_weight_halving_days"]},
		:trust_metric_ids => {Plugs.TrustMetricIdsParam, [name: "trust_metric_url"]},
	},
	def details(conn, params = %{:poll => poll, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "details.html",
			title: Poll.title(poll),
			datetime_text: Timex.format!(datetime, "{ISOdate}"),
			poll: prepare_poll(poll, params),
			contributions: prepare_contributions(poll, params),
			results_with_datetime: prepare_results_with_datetime(poll, 30, params)
	end)

	plug :put_layout, "minimal.html" when action in [:embed]
	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id"]},
		:trust_metric_ids => {Plugs.TrustMetricIdsParam, [name: "trust_metric_url"]},
	},
	def embed(conn, params = %{:poll => poll}) do
		params = Map.marge(params, %{
			:datetime =>  Timex.DateTime.now,
			:vote_weight_halving_days => nil
		})

		conn
		|> render "embed.html",
			poll: prepare_poll(poll, params),
			references: prepare_references(poll, params)
	end)

	defp prepare_poll(poll, %{:datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		poll
		|> Map.put(:results, Result.calculate(poll, datetime, trust_metric_ids, vote_weight_halving_days, 1))
		|> Map.put(:title, Poll.title(poll))
	end

	defp prepare_references(poll, %{:datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		Reference.for_poll(poll, datetime, vote_weight_halving_days, trust_metric_ids)
	end

	defp prepare_contributions(poll, %{:datetime => datetime, :trust_metric_ids => trust_metric_ids}) do
		Result.calculate_contributions(poll, datetime, trust_metric_ids)
	end

	defp prepare_results_with_datetime(poll, num_units, %{:datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		Enum.map(0..num_units, fn(shift_units) ->
			datetime = Timex.shift(datetime, days: -shift_units)
			{
				num_units - shift_units,
				datetime,
				Result.calculate(poll, datetime, trust_metric_ids, vote_weight_halving_days, 1)
			}
		end)
	end
end