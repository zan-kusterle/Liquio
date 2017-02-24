defmodule Liquio.DelegationController do
	use Liquio.Web, :controller

	plug :scrub_params, "delegation" when action in [:create]
	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
	},
	def create(conn, %{:user => user, "delegation" => params}) do
		params = params |> Map.put("from_identity_id", user.id)
		changeset = Delegation.changeset(%Delegation{}, params)
		case Delegation.set(changeset) do
			{:ok, delegation} ->
				delegation = Repo.preload delegation, [:from_identity, :to_identity]
				conn
				|> put_status(:created)
				|> put_resp_header("location", identity_delegation_path(conn, :show, user.id, delegation))
				|> render("show.json", delegation: delegation)
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Liquio.ChangesetView, "error.json", changeset: changeset)
		end
	end)

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:to_identity => {Plugs.ItemParam, [schema: Identity, name: "id"]}
	},
	def delete(conn, %{:user => user, :to_identity => to_identity}) do
		delegation = Repo.get_by(Delegation, %{from_identity_id: user.id, to_identity_id: to_identity.id, is_last: true})
		if delegation do
			Delegation.unset(user, to_identity)
			conn
			|> send_resp(:no_content, "")
		else
			conn
			|> put_status(:not_found)
			|> render(Liquio.ErrorView, "error.json", message: "Delegation does not exist")
		end
	end)
end
