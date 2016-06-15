defmodule Democracy.ReferenceController do
	use Democracy.Web, :controller

	alias Democracy.Reference
	alias Democracy.Poll

	plug :scrub_params, "reference" when action in [:create]

	def index(conn, %{"poll_id" => poll_id}) do
		poll = Repo.get(Poll, poll_id)
		if poll do
			references = from(d in Reference, where: d.poll_id == ^poll.id, order_by: d.created_at)
			|> Repo.all
			|> Repo.preload([:approval_poll])
			|> Enum.filter(fn(reference) ->
				approval_result = Result.calculate(reference.approval_poll, Ecto.DateTime.utc(), MapSet.new(Enum.to_list 1..1000000))
				is_approved = approval_result["mean"] > 0.5 and approval_result["total"] > 1
				is_approved
			end)

			conn
			|> render("index.json", references: references)
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Poll does not exist")
		end
	end

	def create(conn, %{"poll_id" => poll_id, "reference" => params}) do
		poll = Repo.get(Poll, poll_id)
		if poll do
			params = Map.put(params, "poll_id", poll.id)
			changeset = Reference.changeset(%Reference{}, params)
			case Reference.create(changeset) do
				{:ok, reference} ->
					conn
					|> put_status(:created)
					|> put_resp_header("location", poll_reference_path(conn, :show, poll.id, reference))
					|> render("show.json", reference: reference)
				{:error, changeset} ->
					conn
					|> put_status(:unprocessable_entity)
					|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
			end
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Poll does not exist")
		end
	end

	def show(conn, %{"poll_id" => poll_id, "id" => reference_id}) do
		poll = Repo.get(Poll, poll_id)
		reference = Repo.get(Reference, reference_id)
		if poll do
			if reference != nil and reference.poll_id == poll.id do
				conn
				|> render("show.json", reference: reference)
			else
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: "Reference does not exist")
			end
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Poll does not exist")
		end
	end
end