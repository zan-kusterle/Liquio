defmodule Democracy.HtmlPollController do
	use Democracy.Web, :controller

	alias Democracy.Repo
	alias Democracy.Poll
	alias Democracy.Reference
	alias Democracy.TrustMetric
	alias Democracy.Result

	plug Democracy.Plugs.QueryId, {:poll, Poll, "id"} when action in [:show]
	plug Democracy.Plugs.QueryId, {:poll, Poll, "html_poll_id"} when action in [:details, :embed]
	plug Democracy.Plugs.Datetime, {:datetime, "datetime"}
	plug Democracy.Plugs.TrustMetricIds, {:trust_metric_ids, "trust_metric_url"} when action in [:show, :details, :embed]
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"}
	plug Democracy.Plugs.TopicsQuery, {:topics, "topics"} when action in [:create]
	plug Democracy.Plugs.ChoiceType, {:choice_type, "choice_type", :topics} when action in [:create]
	plug Democracy.Plugs.Title, {:title, "title"} when action in [:create]

	plug :put_layout, "minimal.html" when action in [:embed]
	
	def new(conn, _params) do
		conn
		|> render "new.html"
	end

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
			datetime_text: Map.get(params, "datetime", ""),
			poll: poll
				|> Map.put(:results, Result.calculate(poll, datetime, trust_metric_ids, vote_weight_halving_days, 1))
				|> Map.put(:title, Poll.title(poll)),
			contributions: Result.calculate_contributions(poll, datetime, trust_metric_ids),
			results_with_datetime: results_with_datetime
	end

	def embed(conn, %{:poll => poll, :trust_metric_ids => trust_metric_ids}) do
		datetime = Timex.DateTime.now

		conn
		|> render "embed.html",
			poll: poll
				|> Map.put(:results, Result.calculate(poll, datetime, trust_metric_ids, nil, 1))
				|> Map.put(:title, Poll.title(poll)),
			references: Reference.for_poll(conn.params.poll, datetime, nil, trust_identity_ids)
	end
end