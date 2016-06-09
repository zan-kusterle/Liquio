import Ecto.Query, only: [from: 2]

defmodule Democracy.DelegationController do
	use Democracy.Web, :controller
	use Guardian.Phoenix.Controller

	alias Democracy.Identity
	alias Democracy.Delegation

	plug :scrub_params, "delegation" when action in [:create, :update]

	def index(conn, %{"identity_id" => from_identity_username}) do
		from_identity = Repo.get_by!(Identity, username: from_identity_username)

		query = from d in Delegation,
			where: d.from_identity_id == ^from_identity.id,
			select: d
		delegations = Repo.all(query) |> Repo.preload([:from_identity, :to_identity])

		render(conn, "index.json", delegations: delegations)
	end

	def create(conn, %{"identity_id" => from_identity_username, "delegation" => %{"to_identity_id" => to_identity_username, "weight" => weight, "topics" => topics}}, user, claims) do
		from_identity = Repo.get_by!(Identity, username: from_identity_username)
		to_identity = Repo.get_by!(Identity, username: to_identity_username)

		if user.id == from_identity.id do
			changeset = Delegation.changeset(%Delegation{
				from_identity_id: from_identity.id,
				to_identity_id: to_identity.id,
				weight: weight * 1.0,
				topics: topics
			}, %{})

			case Repo.insert(changeset) do
				{:ok, delegation} ->
					delegation = Repo.preload delegation, :from_identity
					delegation = Repo.preload delegation, :to_identity
					conn
					|> put_status(:created)
					|> put_resp_header("location", identity_delegation_path(conn, :show, from_identity, delegation))
					|> render("show.json", delegation: delegation)
				{:error, changeset} ->
					conn
					|> put_status(:unprocessable_entity)
					|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
			end
		else
			send_resp(conn, :unauthorized, "Current user should be from user")
		end
	end

	def show(conn, %{"user_id" => from_user_username, "id" => to_user_username}, user, claims) do
		from_user = Repo.get_by!(User, username: from_user_username)
		to_user = Repo.get_by!(User, username: to_user_username)

		query = from d in Delegation,
			where: d.from_user == ^from_user and d.to_user == ^to_user,
			select: d

		delegation = Repo.get!(query)

		render(conn, "show.json", delegation: delegation)
	end

	def delete(conn, %{"user_id" => from_user_username, "id" => to_user_username}, user, claims) do
		from_user = Repo.get_by!(User, username: from_user_username)
		to_user = Repo.get_by!(User, username: to_user_username)

		if conn.user == from_user do
			query = from d in Delegation,
				where: d.from_user == ^from_user and d.to_user == ^to_user,
				select: d
			delegation = Repo.get!(query)

			Repo.delete!(delegation)

			send_resp(conn, :no_content, "")
		else
			send_resp(conn, :unauthorized, "Current user should be from user")
		end
	end
end
