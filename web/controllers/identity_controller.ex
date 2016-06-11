defmodule Democracy.IdentityController do
	use Democracy.Web, :controller

	alias Democracy.Identity

	plug :scrub_params, "identity" when action in [:create, :update]

	def index(conn, %{}) do
		identities = Repo.all(Identity)

		render(conn, "index.json", identities: identities)
	end

	def create(conn, %{"identity" => params}) do
		changeset = Identity.changeset(%Identity{}, params)
		if changeset.valid? do
			identity = Identity.create(changeset)
			conn
			|> put_status(:created)
			|> put_resp_header("location", identity_path(conn, :show, Map.put(identity, :id, identity.username)))
			|> render("show.json", identity: Map.put(identity, :insecure_token, identity.token))
		else
			conn
			|> put_status(:unprocessable_entity)
			|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
		end
	end

	def show(conn, %{"username" => username}) do
		identity = Repo.get_by(Identity, username: username)
		if identity do
			render(conn, "show.json", identity: identity)
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Identity does not exist")
		end
	end
end
