defmodule Democracy.IdentityController do
	use Democracy.Web, :controller

	alias Democracy.Identity

	plug :scrub_params, "identity" when action in [:create]

	plug Democracy.Plugs.QueryIdentityIdFallbackCurrent, {:identity, "id"} when action in [:show]

	def index(conn, %{}) do
		identities = Repo.all(Identity) |> Repo.preload([:trust_metric_poll_votes])
		render(conn, "index.json", identities: identities)
	end

	def create(conn, %{"identity" => params}) do
		token = Identity.generate_token()
		changeset = Identity.changeset(%Identity{token: token}, params)
		case Identity.create(changeset) do
			{:ok, identity} ->
				conn
				|> put_status(:created)
				|> put_resp_header("location", identity_path(conn, :show, identity))
				|> render("show.json", identity: Map.put(identity, :insecure_token, token))
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
		end
	end

	def show(conn, _params) do
		identity = conn.assigns.identity |> Repo.preload([:trust_metric_poll_votes])
		render(conn, "show.json", identity: identity)
	end

	def update(conn, %{"id" => id, "identity" => params}) do
		# TODO: Update preferences
	end
end
