defmodule Democracy.PollController do
	use Democracy.Web, :controller

	alias Democracy.Poll
	alias Democracy.Result
	alias Democracy.TrustMetric

	plug :scrub_params, "poll" when action in [:create]

	plug Democracy.Plugs.Datetime, {:datetime, "datetime"} when action in [:show, :contributions]
	plug Democracy.Plugs.TrustMetricUrl, {:trust_metric_url, "trust_metric_url"} when action in [:show, :contributions]
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"} when action in [:show]
	
	plug Democracy.Plugs.QueryId, {:poll, Poll, "id"} when action in [:show]
	plug Democracy.Plugs.QueryId, {:poll, Poll, "poll_id"} when action in [:contributions]

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

	def show(conn, _params) do
		# TODO: Get polls in same category (for every category poll where current category is proposed calculate best category)
		# Do this by periodically updating :group_title field on kind=custom polls. Use default trust metric here, because the category can be custom changed by each user if they want (this is just the default)
		# TODO: Give option to select a different list (it's automatically saved and used from then on, with reset option)
		# TODO: Pick the one with the most voting power. If it is the same as conn.params.poll then show it, otherwise return a redirect response.
		case TrustMetric.get(conn.params.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				results = Result.calculate(conn.params.poll, conn.params.datetime, trust_identity_ids, conn.params.vote_weight_halving_days, 1)
				conn
				|> render("show.json", poll: conn.params.poll |> Map.put(:results, results))
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
	end

	def contributions(conn, _params) do
		case TrustMetric.get(conn.params.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				contributions = Result.calculate_contributions(conn.params.poll, conn.params.datetime, trust_identity_ids) |> Enum.map(fn(contribution) ->
					%{
						:datetime => Timex.format!(contribution.datetime, "{ISO}"),
						:score => contribution.score,
						:voting_power => contribution.voting_power,
						:identity_id => contribution.identity_id
					}
				end)
				conn
				|> render("results.json", results: contributions)
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
		
	end
end
