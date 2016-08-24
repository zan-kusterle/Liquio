defmodule Liquio.IdentityController do
	use Liquio.Web, :controller

	def index(conn, %{}) do
		identities = Identity |> Repo.all |> Repo.preload([:trust_metric_poll_votes])
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
				|> render(Liquio.ChangesetView, "error.json", changeset: changeset)
		end
	end

	with_params(%{
		:identity => {Plugs.IdentityParam, [name: "id"]}
	},
	def show(conn, %{:identity => identity}) do
		identity = identity |> Repo.preload([:trust_metric_poll_votes])
		render(conn, "show.json", identity: identity)
	end)

	def update(_conn, %{"id" => _id, "identity" => _params}) do
	end
end
