defmodule Democracy.ReferenceController do
	use Democracy.Web, :controller

	alias Democracy.Reference
	alias Democracy.Poll
	alias Democracy.TrustMetric

	plug :scrub_params, "reference" when action in [:create]

	plug Democracy.Plugs.Datetime, {:datetime, "datetime"} when action in [:index]
	plug Democracy.Plugs.TrustMetricUrl, {:trust_metric_url, "trust_metric_url"} when action in [:index]
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"} when action in [:index]
	
	plug Democracy.Plugs.QueryId, {:poll, Poll, "poll_id"}
	plug Democracy.Plugs.QueryId, {:reference, Reference, "id"} when action in [:show]

	def index(conn, params) do
		# TODO: Inverse references, all references / only approved
		# TODO: Is approved config in params (mean, total)
		references = from(d in Reference, where: d.poll_id == ^conn.assigns.poll.id, order_by: d.created_at)
		|> Repo.all
		|> Repo.preload([:approval_poll])
		|> Enum.filter(fn(reference) ->
			approval_result = Result.calculate(reference.approval_poll, conn.assigns.datetime, TrustMetric.get(conn.assigns.trust_metric_url), conn.assigns.vote_weight_halving_days)["true"]
			is_approved = approval_result["mean"] > 0.5 and approval_result["total"] >= 1
			is_approved
		end)

		conn
		|> render("index.json", references: references)
	end

	def create(conn, %{"reference" => params}) do
		params = Map.put(params, "poll_id", conn.assigns.poll.id)
		changeset = Reference.changeset(%Reference{}, params)
		case Reference.create(changeset) do
			{:ok, reference} ->
				conn
				|> put_status(:created)
				|> put_resp_header("location", poll_reference_path(conn, :show, conn.assigns.poll.id, reference))
				|> render("show.json", reference: reference)
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
		end
	end

	def show(conn, _params) do
		conn
		|> render("show.json", reference: conn.assigns.reference)
	end
end