defmodule Democracy.PollOverviewController do
	use Democracy.Web, :controller

	alias Democracy.Poll
	alias Democracy.Reference
	alias Democracy.TrustMetric
	alias Democracy.Result

	plug Democracy.Plugs.QueryId, {:poll, Poll, "id"} when action in [:show]
	plug Democracy.Plugs.QueryId, {:poll, Poll, "poll_overview_id"} when action in [:details]
	plug Democracy.Plugs.Datetime, {:datetime, "datetime"}
	plug Democracy.Plugs.TrustMetricUrl, {:trust_metric_url, "trust_metric_url"}
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"}
	
	def show(conn, _params) do
		case TrustMetric.get(conn.assigns.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				references = Reference.for_poll(conn.assigns.poll, conn.assigns.datetime, conn.assigns.vote_weight_halving_days, trust_identity_ids)
				results = Result.calculate(conn.assigns.poll, conn.assigns.datetime, trust_identity_ids, conn.assigns.vote_weight_halving_days, 1)
				poll = conn.assigns.poll |> Map.put(:results, results)
				conn
				|> render "show.html", poll: poll, references: references
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
	end

	def details(conn, _params) do
		case TrustMetric.get(conn.assigns.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				contributions = Result.calculate_contributions(conn.assigns.poll, conn.assigns.datetime, trust_identity_ids)
				results = Result.calculate(conn.assigns.poll, conn.assigns.datetime, trust_identity_ids, conn.assigns.vote_weight_halving_days, 1)
				poll = conn.assigns.poll |> Map.put(:results, results)
				conn
				|> render "details.html", datetime_text: _params["datetime"], poll: poll, contributions: contributions
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
	end
end