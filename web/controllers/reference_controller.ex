defmodule Democracy.ReferenceController do
	use Democracy.Web, :controller

	alias Democracy.Reference
	alias Democracy.Poll

	plug :scrub_params, "reference" when action in [:create]

	def index(conn, %{"poll_id" => poll_id}) do
		poll = Repo.get(Poll, poll_id)
		if poll do
			references = from(d in Reference, where: d.poll_id == ^poll.id)
			|> Repo.all
			|> Repo.preload([:approval_poll])

			conn
			|> render("index.json", references: references)
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Poll does not exist")
		end
	end

	def create(conn, %{"poll_id" => poll_id, "reference" => params}) do
		params = Map.put(params, "poll_id", poll_id)
		changeset = Reference.changeset(%Reference{}, params)
		case Reference.create(changeset) do
			{:ok, reference} ->
				conn
				|> put_status(:created)
				|> put_resp_header("location", poll_reference_path(conn, :show, reference))
				|> render("show.json", reference: reference)
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
		end
	end
end