defmodule Democracy.ReferenceController do
	use Democracy.Web, :controller

	alias Democracy.Reference
	alias Democracy.Poll
	alias Democracy.TrustMetric

	plug :scrub_params, "reference" when action in [:create]
	plug :get_poll
	plug :get_reference

	defp get_poll(conn, _) do
		poll = Repo.get(Poll, conn.params["poll_id"])
		if poll do
			assign(conn, :poll, poll)
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Poll does not exist")
			|> halt
		end
	end

	defp get_reference(conn, _) do
		if Map.has_key?(conn.params, "id") do
			reference = Repo.get(Reference, conn.params["id"])
			if reference do
				assign(conn, :reference, reference)
			else
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: "Reference does not exist")
				|> halt
			end
		else
			conn
		end
	end

	def index(conn, params = %{"poll_id" => poll_id}) do
		# TODO: Inverse references, all references / only approved
		# TODO: Is approved config in params (mean, total)
		trust_metric_url = Map.get(params, "trust_metric_url") || TrustMetric.default_trust_metric_url()
		vote_weight_halving_days =
			if Map.get(params, "vote_weight_halving_days") do
				{value, _} = Integer.parse(params["vote_weight_halving_days"])
				value
			else
				nil
			end
		datetime =
			if Map.get(params, "datetime") do
				Ecto.DateTime.cast!(params["datetime"])
			else
				Ecto.DateTime.utc()
			end

		references = from(d in Reference, where: d.poll_id == ^conn.assigns.poll.id, order_by: d.created_at)
		|> Repo.all
		|> Repo.preload([:approval_poll])
		|> Enum.filter(fn(reference) ->
			approval_result = Result.calculate(reference.approval_poll, datetime, TrustMetric.get(trust_metric_url), vote_weight_halving_days)["true"]
			is_approved = approval_result["mean"] > 0.5 and approval_result["total"] >= 1
			is_approved
		end)

		conn
		|> render("index.json", references: references)
	end

	def create(conn, %{"poll_id" => poll_id, "reference" => params}) do
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