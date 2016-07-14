defmodule Democracy.ReferenceController do
	use Democracy.Web, :controller

	alias Democracy.Reference
	alias Democracy.Poll
	alias Democracy.TrustMetric
	alias Democracy.Result

	plug :scrub_params, "reference" when action in [:create]

	plug Democracy.Plugs.Datetime, {:datetime, "datetime"} when action in [:index]
	plug Democracy.Plugs.TrustMetricUrl, {:trust_metric_url, "trust_metric_url"} when action in [:index]
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"} when action in [:index]
	
	plug Democracy.Plugs.QueryId, {:poll, Poll, "poll_id"}
	plug Democracy.Plugs.QueryId, {:reference_poll, Poll, "id"} when action in [:show]
	plug Democracy.Plugs.Datetime, {:datetime, "datetime"} when action in [:show]
	plug Democracy.Plugs.TrustMetricUrl, {:trust_metric_url, "trust_metric_url"} when action in [:show]
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"} when action in [:show]
	plug Democracy.Plugs.FloatQuery, {:for_choice, "for_choice"} when action in [:show]

	def index(conn, %{"threshold" => threshold}) do
		case TrustMetric.get(conn.assigns.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				references = Reference.for_poll(conn.assigns.poll, conn.assigns.datetime, conn.assigns.vote_weight_halving_days, trust_identity_ids)
				conn
				|> render("index.json", references: references)
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
	end

	def show(conn, _params) do
		case TrustMetric.get(conn.assigns.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				reference = Reference.get(conn.assigns.poll, conn.assigns.reference_poll, conn.assigns.for_choice)
				|> Repo.preload([:approval_poll, :reference_poll, :poll])
				results = Result.calculate(reference.approval_poll, conn.assigns.datetime, trust_identity_ids, conn.assigns.vote_weight_halving_days, 1)
				reference = Map.put(reference, :approval_poll, Map.put(reference.approval_poll, :results, results))
				conn
				|> render("show.json", reference: reference)
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
	end
end