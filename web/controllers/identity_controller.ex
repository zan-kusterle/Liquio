defmodule Democracy.IdentityController do
	use Democracy.Web, :controller

	def index(conn, %{}) do
		identities = Repo.all(Identity) |> Repo.preload([:trust_metric_poll_votes])
		render(conn, "index.json", identities: identities)
	end

	plug :scrub_params, "identity" when action in [:create]
	def create(conn, %{"identity" => params}) do
		password = Identity.generate_password()
		changeset = Identity.changeset(%Identity{
			password_hash: Comeonin.Bcrypt.hashpwsalt(password)
		}, params)
		case Identity.create(changeset) do
			{:ok, identity} ->
				conn
				|> put_status(:created)
				|> put_resp_header("location", identity_path(conn, :show, identity))
				|> render("show.json", identity: Map.put(identity, :insecure_password, password))
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
		end
	end

	with_params(%{
		:identity => {Plugs.IdentityParam, [name: "id"]}
	},
	def show(conn, %{:identity => identity}) do
		identity = identity |> Repo.preload([:trust_metric_poll_votes])
		render(conn, "show.json", identity: identity)
	end)

	def update(conn, %{"id" => id, "identity" => params}) do
		# TODO: Update preferences
	end
end
