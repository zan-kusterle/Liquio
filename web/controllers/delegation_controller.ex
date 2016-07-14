defmodule Democracy.DelegationController do
	use Democracy.Web, :controller

	import Ecto.Query, only: [from: 2]
	alias Democracy.Identity
	alias Democracy.Delegation

	plug :scrub_params, "delegation" when action in [:create]

	plug Democracy.Plugs.QueryIdentityIdFallbackCurrent, {:from_identity, "identity_id"} when action in [:index, :show]
	plug Democracy.Plugs.QueryIdentityIdEnsureCurrent, {:from_identity, "identity_id"} when action in [:create, :delete]
	plug Democracy.Plugs.QueryId, {:to_identity, Identity, "id"} when action in [:show, :delete]

	def index(conn, _params) do
		delegations = from(d in Delegation, where: d.from_identity_id == ^conn.params.from_identity.id and d.is_last == true and not is_nil(d.data))
		|> Repo.all
		|> Repo.preload([:from_identity, :to_identity])

		conn
		|> render("index.json", delegations: delegations)
	end

	def create(conn, %{"delegation" => params}) do
		params = params |> Map.put("from_identity_id", conn.params.from_identity.id)
		changeset = Delegation.changeset(%Delegation{}, params)
		case Delegation.set(changeset) do
			{:ok, delegation} ->
				delegation = Repo.preload delegation, [:from_identity, :to_identity]
				conn
				|> put_status(:created)
				|> put_resp_header("location", identity_delegation_path(conn, :show, conn.params.from_identity.id, delegation))
				|> render("show.json", delegation: delegation)
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
		end
	end

	def show(conn, _params) do
		delegation = Repo.all(from(d in Delegation, where:
			d.from_identity_id == ^conn.params.from_identity.id and d.to_identity_id == ^conn.params.to_identity.id
			and d.is_last == true and not is_nil(d.data))) |> Enum.at(0)
		if delegation do
			delegation = Repo.preload delegation, [:from_identity, :to_identity]
			conn
			|> render("show.json", delegation: delegation)
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Delegation does not exist")
		end
	end

	def delete(conn, _params) do
		delegation = Repo.get_by(Delegation, %{from_identity_id: conn.params.from_identity.id, to_identity_id: conn.params.to_identity.id, is_last: true})
		if delegation do
			Delegation.unset(conn.params.from_identity, conn.params.to_identity)
			conn
			|> send_resp(:no_content, "")
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Delegation does not exist")
		end
	end
end
