defmodule Liquio.Web.IdentityController do
	use Liquio.Web, :controller

	def index(conn, %{}) do
		identities = Identity |> Repo.all
		render(conn, "index.json", identities: identities)
	end

	plug :scrub_params, "identity" when action in [:create]
	def create(conn, %{"token" => token, "identity" => params}) do
		email = Token.get_email(token)
		if email == nil do
			conn
			|> redirect(to: "/login")
		else
			identity = Identity.create(Identity.changeset(%Identity{email: email}, params))
			Token.use(token)
			conn
			|> Guardian.Plug.sign_in(identity)
			|> redirect(to: "/")
		end
	end

	with_params(%{
		:identity => {Plugs.IdentityParam, [name: "id", column: :username]}
	},
	def show(conn, %{:identity => identity}) do
		render(conn, "show.json", identity: identity |> Identity.preload())
	end)


	plug :scrub_params, "delegation" when action in [:put]
	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:to_identity => {Plugs.ItemParam, [schema: Identity, name: "identity_id", column: "username"]}
	},
	def update(conn, %{:user => user, :to_identity => to_identity, "delegation" => params}) do
		params = params |> Map.put("from_identity_id", user.id) |> Map.put("to_identity_id", to_identity.id)
		changeset = Delegation.changeset(%Delegation{}, params)
		case Delegation.set(changeset) do
			{:ok, delegation} ->
				delegation = Repo.preload delegation, [:from_identity, :to_identity]
				conn
				|> put_resp_header("location", identity_path(conn, :show, user.id))
				|> put_status(:created)
				|> render(Liquio.Web.IdentityView, "show.json", identity: Repo.get!(Identity, user.id) |> Identity.preload())
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Liquio.Web.ChangesetView, "error.json", changeset: changeset)
		end
	end)

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:to_identity => {Plugs.ItemParam, [schema: Identity, name: "identity_id", column: "username"]}
	},
	def delete(conn, %{:user => user, :to_identity => to_identity}) do
		delegation = Repo.get_by(Delegation, %{from_identity_id: user.id, to_identity_id: to_identity.id, to_datetime: nil})
		if delegation do
			Delegation.unset(user, to_identity)
			conn
			|> put_status(:ok)
			|> render(Liquio.Web.IdentityView, "show.json", identity: Repo.get!(Identity, user.id) |> Identity.preload())
		else
			conn
			|> put_status(:not_found)
			|> render(Liquio.Web.ErrorView, "error.json", message: "Delegation does not exist")
		end
	end)
end
