defmodule Democracy.HtmlReferenceController do
	use Democracy.Web, :controller

	alias Democracy.Poll
	alias Democracy.Reference
	alias Democracy.TrustMetric
	alias Democracy.Result

	plug Democracy.Plugs.QueryId, {:poll, Poll, "html_poll_id"}
	plug Democracy.Plugs.QueryId, {:reference_poll, Poll, "id"} when action in [:show]
	plug Democracy.Plugs.Datetime, {:datetime, "datetime"} when action in [:show]
	plug Democracy.Plugs.TrustMetricUrl, {:trust_metric_url, "trust_metric_url"} when action in [:show]
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"} when action in [:show]

	def index(conn, %{"reference_poll_id" => reference_poll_id, "pole" => pole}) do
		conn
		|> redirect to: html_poll_html_reference_path(conn, :show, conn.assigns.poll.id, reference_poll_id, pole: pole)
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
					|> render("show.html", reference: reference)
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