defmodule Democracy.IdentityController do
	use Democracy.Web, :controller

	alias Democracy.Identity

	plug :scrub_params, "identity" when action in [:create]

	def index(conn, %{}) do
		identities = Repo.all(Identity) |> Repo.preload([:trust_metric_poll_votes])
		render(conn, "index.json", identities: identities)
	end

	def create(conn, %{"identity" => params}) do
		changeset = Identity.changeset(%Identity{}, params)
		case Identity.create(changeset) do
			{:ok, identity} ->
				conn
				|> put_status(:created)
				|> put_resp_header("location", identity_path(conn, :show, identity))
				|> render("show.json", identity: Map.put(identity, :insecure_token, identity.token))
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
		end
	end

	def show(conn, %{"id" => id}) do
		# TODO: Id can be "me", show preferences in view if id = current user
		identity = Repo.get(Identity, id)
		if identity do
			identity = identity |> Repo.preload([:trust_metric_poll_votes])
			render(conn, "show.json", identity: identity)
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Identity does not exist")
		end
	end

	def update(conn, %{"id" => id, "identity" => params}) do
		# TODO: Update preferences
	end
end
