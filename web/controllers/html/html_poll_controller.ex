defmodule Democracy.HtmlPollController do
	use Democracy.Web, :controller

	alias Democracy.Repo
	alias Democracy.Poll
	alias Democracy.Reference
	alias Democracy.TrustMetric
	alias Democracy.Result

	plug :put_layout, "minimal.html" when action in [:embed]
	
	def new(conn, _) do
		conn
		|> render "new.html"
	end

	plug Democracy.Plugs.Params, [
		{&Democracy.Plugs.TopicsParam.handle/2, :topics, [name: "topics"]},
		{&Democracy.Plugs.ChoiceTypeParam.handle/2, :choice_type, [name: "choice_type", topics_name: :topics]},
		{&Democracy.Plugs.TitleParam.handle/2, :title, [name: "title"]}
	] when action in [:create]
	def create(conn, %{:choice_type => choice_type, :title => title, :topics => topics}) do
		poll = Poll.create(choice_type, title, topics)
		conn
		|> put_flash(:info, "Done, share the url so others can vote")
		|> redirect to: html_poll_path(conn, :show, poll.id)
	end

	def show(conn, %{"id" => "random"}) do
		conn
		|> redirect to: html_poll_path(conn, :show, Poll.get_random().id)
	end

	plug Democracy.Plugs.Params, [
		{&Democracy.Plugs.ItemParam.handle/2, :poll, [schema: Poll, name: "id"]},
		{&Democracy.Plugs.DatetimeParam.handle/2, :datetime, [name: "datetime"]},
		{&Democracy.Plugs.VoteWeightHalvingDaysParam.handle/2, :vote_weight_halving_days, [name: "vote_weight_halving_days"]},
		{&Democracy.Plugs.TrustMetricIdsParam.handle/2, :trust_metric_ids, [name: "trust_metric_url"]},
	] when action in [:show]
	def show(conn, %{:poll => poll, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "show.html",
			title: Poll.title(poll),
			is_logged_in: Guardian.Plug.current_resource(conn) != nil,
			poll: poll
                |> Map.put(:results, Result.calculate(poll, datetime, trust_metric_ids, vote_weight_halving_days, 1))
                |> Map.put(:title, Poll.title(poll)),
			references: Reference.for_poll(poll, datetime, vote_weight_halving_days, trust_metric_ids)
	end

	plug Democracy.Plugs.Params, [
		{&Democracy.Plugs.ItemParam.handle/2, :poll, [schema: Poll, name: "html_poll_id"]},
		{&Democracy.Plugs.DatetimeParam.handle/2, :datetime, [name: "datetime"]},
		{&Democracy.Plugs.VoteWeightHalvingDaysParam.handle/2, :vote_weight_halving_days, [name: "vote_weight_halving_days"]},
		{&Democracy.Plugs.TrustMetricIdsParam.handle/2, :trust_metric_ids, [name: "trust_metric_url"]},
	] when action in [:details]
	def details(conn, %{:poll => poll, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		num_units = 30
		results_with_datetime = Enum.map(0..num_units, fn(shift_units) ->
			datetime = Timex.shift(datetime, days: -shift_units)
			{
				num_units - shift_units,
				datetime,
				Result.calculate(poll, datetime, trust_metric_ids, vote_weight_halving_days, 1)
			}
		end)

		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "details.html",
			title: Poll.title(poll),
			datetime_text: Timex.format!(datetime, "{D}.{M}.{YYYY}"),
			poll: poll
				|> Map.put(:results, Result.calculate(poll, datetime, trust_metric_ids, vote_weight_halving_days, 1))
				|> Map.put(:title, Poll.title(poll)),
			contributions: Result.calculate_contributions(poll, datetime, trust_metric_ids),
			results_with_datetime: results_with_datetime
	end

	plug Democracy.Plugs.Params, [
		{&Democracy.Plugs.ItemParam.handle/2, :poll, [schema: Poll, name: "html_poll_id"]},
		{&Democracy.Plugs.TrustMetricIdsParam.handle/2, :trust_metric_ids, [name: "trust_metric_url"]},
	] when action in [:embed]
	def embed(conn, %{:poll => poll, :trust_metric_ids => trust_metric_ids}) do
		datetime = Timex.DateTime.now

		conn
		|> render "embed.html",
			poll: poll
				|> Map.put(:results, Result.calculate(poll, datetime, trust_metric_ids, nil, 1))
				|> Map.put(:title, Poll.title(poll)),
			references: Reference.for_poll(poll, datetime, nil, trust_metric_ids)
	end
end