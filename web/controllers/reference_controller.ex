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

	def index(conn, %{"threshold" => threshold}) do
		case TrustMetric.get(conn.assigns.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				references = from(d in Reference, where: d.poll_id == ^conn.assigns.poll.id, order_by: d.inserted_at)
				|> Repo.all
				|> Repo.preload([:approval_poll, :reference_poll, :poll])
				|> Enum.filter(fn(reference) ->
					approval_result = Result.calculate(reference.approval_poll, conn.assigns.datetime, trust_identity_ids, conn.assigns.vote_weight_halving_days, 1)
					is_approved = approval_result.mean >= 0.5
					is_approved
				end)
				|> Enum.map(fn(reference) ->
					results = Result.calculate(reference.reference_poll, conn.assigns.datetime, trust_identity_ids, conn.assigns.vote_weight_halving_days, 1)
					Map.put(reference, :reference_poll, Map.put(reference.reference_poll, :results, results))
				end)
				|> Enum.sort(&(&1.reference_poll.results.mean > &2.reference_poll.results.mean))

				conn
				|> render("index.json", references: references)
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
	end

	def show(conn, %{"pole" => pole}) do
		if pole == "positive" or pole == "negative" do
			case TrustMetric.get(conn.assigns.trust_metric_url) do
				{:ok, trust_identity_ids} ->
					reference = Reference.get(conn.assigns.poll, conn.assigns.reference_poll, pole)
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
		else
			conn
			|> put_status(:not_found)
			|> Phoenix.Controller.render(Democracy.ErrorView, "error.json", message: "Pole must be positive or negative")
		end
	end
end