defmodule Liquio.Web.IdentityController do
	use Liquio.Web, :controller

	def index(conn, %{}) do
		identities = Identity.all()
		render(conn, "index.json", identities: identities)
	end

	def show(conn, %{"id" => username}) do
		render(conn, "show.json", identity: Identity.preload(username))
	end

	def update(conn, params = %{"public_key" => public_key, "signature" => signature, "id" => to_username}) do
		case Delegation.set(Base.decode64!(public_key), Base.decode64!(signature), to_username, Map.get(params, "is_trusting"), Map.get(params, "weight"), Map.get(params, "topics")) do
			{:ok, delegation} ->
				conn
				|> put_resp_header("location", identity_path(conn, :show, to_username))
				|> put_status(:created)
				|> render(Liquio.Web.IdentityView, "show.json", identity: Identity.preload(to_username))
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Liquio.Web.ChangesetView, "error.json", changeset: changeset)
		end
	end

	def delete(conn, %{"public_key" => public_key, "signature" => signature, "id" => to_username}) do
		username = Identity.username_from_key(public_key)
		delegation = Delegation.get_by(username, to_username)

		if delegation do
			Delegation.unset(Base.decode64!(public_key), Base.decode64!(signature), to_username)
			conn
			|> put_status(:ok)
			|> render(Liquio.Web.IdentityView, "show.json", identity: Identity.preload(to_username))
		else
			conn
			|> put_status(:not_found)
			|> render(Liquio.Web.ErrorView, "error.json", message: "Delegation does not exist")
		end
	end
end
