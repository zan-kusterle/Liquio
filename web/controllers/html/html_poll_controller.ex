defmodule Democracy.HtmlPollController do
	use Democracy.Web, :controller

	alias Democracy.Poll
	alias Democracy.Reference
	alias Democracy.Result

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
		{&Democracy.Plugs.CurrentUser.handle/2, :user, [require: false]},
		{&Democracy.Plugs.ItemParam.handle/2, :poll, [schema: Poll, name: "id"]},
		{&Democracy.Plugs.DatetimeParam.handle/2, :datetime, [name: "datetime"]},
		{&Democracy.Plugs.VoteWeightHalvingDaysParam.handle/2, :vote_weight_halving_days, [name: "vote_weight_halving_days"]},
		{&Democracy.Plugs.TrustMetricIdsParam.handle/2, :trust_metric_ids, [name: "trust_metric_url"]},
	] when action in [:show]
	def show(conn, params = %{:user => user, :poll => poll, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "show.html",
			title: Poll.title(poll),
			is_logged_in: user != nil,
			poll: prepare_poll(poll, params),
			references: Reference.for_poll(poll, datetime, vote_weight_halving_days, trust_metric_ids)
	end

	plug Democracy.Plugs.Params, [
		{&Democracy.Plugs.ItemParam.handle/2, :poll, [schema: Poll, name: "html_poll_id"]},
		{&Democracy.Plugs.DatetimeParam.handle/2, :datetime, [name: "datetime"]},
		{&Democracy.Plugs.VoteWeightHalvingDaysParam.handle/2, :vote_weight_halving_days, [name: "vote_weight_halving_days"]},
		{&Democracy.Plugs.TrustMetricIdsParam.handle/2, :trust_metric_ids, [name: "trust_metric_url"]},
	] when action in [:details]
	def details(conn, params = %{:poll => poll, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "details.html",
			title: Poll.title(poll),
			datetime_text: Timex.format!(datetime, "{D}.{M}.{YYYY}"),
			poll: prepare_poll(poll, params),
			contributions: prepare_contributions(poll, params),
			results_with_datetime: prepare_results_with_datetime(poll, 30, params)
	end

	plug Democracy.Plugs.Params, [
		{&Democracy.Plugs.ItemParam.handle/2, :poll, [schema: Poll, name: "html_poll_id"]},
		{&Democracy.Plugs.TrustMetricIdsParam.handle/2, :trust_metric_ids, [name: "trust_metric_url"]},
	] when action in [:embed]
	plug :put_layout, "minimal.html" when action in [:embed]
	def embed(conn, params = %{:poll => poll, :trust_metric_ids => trust_metric_ids}) do
		params = Map.marge(params, %{
			:datetime =>  Timex.DateTime.now,
			:vote_weight_halving_days => nil
		})

		conn
		|> render "embed.html",
			poll: prepare_poll(poll, params),
			references: prepare_references(poll, params)
	end

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