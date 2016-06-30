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
	plug Democracy.Plugs.QueryFlag, {:include_unapproved, "include_unapproved"} when action in [:index]
	
	plug Democracy.Plugs.QueryId, {:poll, Poll, "poll_id"}
	plug Democracy.Plugs.QueryId, {:reference, Reference, "id"} when action in [:show]

	def index(conn, _params) do
		# TODO: Is approved threshold in param

		case TrustMetric.get(conn.assigns.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				references = from(d in Reference, where: d.poll_id == ^conn.assigns.poll.id, order_by: d.inserted_at)
				|> Repo.all
				|> Repo.preload([:approval_poll, :reference_poll, :poll])
				|> Enum.map(fn(reference) ->
					approval_result = Result.calculate(reference.approval_poll, conn.assigns.datetime, trust_identity_ids, conn.assigns.vote_weight_halving_days, 1)
					is_approved = approval_result.mean > 0.5
					Map.put(reference, :is_approved, is_approved)
				end)
				if not conn.assigns.include_unapproved do
					references = references |> Enum.filter(fn(reference) ->
						reference.is_approved
					end)
				end
				references = references|> Enum.map(fn(reference) ->
					results = Result.calculate(reference.reference_poll, conn.assigns.datetime, trust_identity_ids, conn.assigns.vote_weight_halving_days, 1)
					Map.put(reference, :reference_poll, Map.put(reference.reference_poll, :results, results))
				end)

				conn
				|> render("index.json", references: references)
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
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