defmodule Democracy.PollController do
	use Democracy.Web, :controller

	plug :scrub_params, "poll" when action in [:create]
	def create(conn, %{"poll" => params}) do
		changeset = Poll.changeset(%Poll{}, params)
		case Poll.create(changeset) do
			{:ok, poll} ->
				poll = Map.put(poll, :results, Result.empty())
				conn
				|> put_status(:created)
				|> put_resp_header("location", poll_path(conn, :show, poll))
				|> render("show.json", poll: poll)
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
		end
	end

	with_params([
		{Plugs.ItemParam, :poll, [schema: Poll, name: "id"]},
		{Plugs.DatetimeParam, :datetime, [name: "datetime"]},
		{Plugs.IntegerParam, :vote_weight_halving_days, [name: "vote_weight_halving_days"]},
		{Plugs.TrustMetricIdsParam, :trust_metric_ids, [name: "trust_metric_ids"]},
	],
	def show(conn, %{:poll => poll, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		results = Result.calculate(poll, datetime, trust_metric_ids, vote_weight_halving_days, 1)
		conn
		|> render("show.json", poll: poll |> Map.put(:results, results))
	end)

	with_params([
		{Plugs.ItemParam, :poll, [schema: Poll, name: "poll_id"]},
		{Plugs.DatetimeParam, :datetime, [name: "datetime"]},
		{Plugs.TrustMetricIdsParam, :trust_metric_ids, [name: "trust_metric_ids"]},
	],
	def contributions(conn, %{:poll => poll, :datetime => datetime, :trust_metric_ids => trust_metric_ids}) do
		contributions = Result.calculate_contributions(poll, datetime, trust_metric_ids) |> Enum.map(fn(contribution) ->
			%{
				:datetime => Timex.format!(contribution.datetime, "{ISO}"),
				:score => contribution.score,
				:voting_power => contribution.voting_power,
				:identity_id => contribution.identity_id
			}
		end)
		conn
		|> render("results.json", results: contributions)
	end)
end
