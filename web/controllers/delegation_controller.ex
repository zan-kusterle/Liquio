import Ecto.Query, only: [from: 2]

defmodule Democracy.DelegationController do
	use Democracy.Web, :controller
	use Guardian.Phoenix.Controller

	alias Democracy.Identity
	alias Democracy.Delegation

	plug :scrub_params, "delegation" when action in [:create]

	def index(conn, %{"identity_id" => from_identity_id}, _, _) do
		from_identity = Repo.get(Identity, from_identity_id)

		if from_identity do
			delegations = from(d in Delegation, where: d.from_identity_id == ^from_identity.id and d.is_last == true and not is_nil(d.data))
			|> Repo.all
			|> Repo.preload([:from_identity, :to_identity])

			conn
			|> render("index.json", delegations: delegations)
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Identity does not exist")
		end
	end

	def create(conn, %{"identity_id" => from_identity_id, "delegation" => params}, user, _) do
		if from_identity_id == "me" do
			from_identity_id = user.id
		end
		if user != nil and to_string(user.id) == to_string(from_identity_id) do
			params = params |> Map.put("from_identity_id", from_identity_id)
			changeset = Delegation.changeset(%Delegation{}, params)
			case Delegation.set(changeset) do
				{:ok, delegation} ->
					delegation = Repo.preload delegation, [:from_identity, :to_identity]
					conn
					|> put_status(:created)
					|> put_resp_header("location", identity_delegation_path(conn, :show, from_identity_id, delegation))
					|> render("show.json", delegation: delegation)
				{:error, changeset} ->
					conn
					|> put_status(:unprocessable_entity)
					|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
			end
		else
			send_resp(conn, :unauthorized, "Can only create delegations for yourself")
		end
	end

	def show(conn, %{"identity_id" => from_identity_id, "id" => to_identity_id}, _, _) do
		from_identity = Repo.get(Identity, from_identity_id)
		to_identity = Repo.get(Identity, to_identity_id)

		cond do
			from_identity && to_identity ->
				delegation = Repo.all(from(d in Delegation, where:
					d.from_identity_id == ^from_identity.id and d.to_identity_id == ^to_identity.id
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
			not from_identity ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: "From identity does not exist")
			not to_identity ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: "To identity does not exist")
		end
	end

	def delete(conn, %{"identity_id" => from_identity_id, "id" => to_identity_id}, user, _) do
		if from_identity_id == "me" do
			from_identity_id = user.id
		end
		if user != nil and to_string(user.id) == to_string(from_identity_id) do
			from_identity = Repo.get(Identity, from_identity_id)
			to_identity = Repo.get(Identity, to_identity_id)

			cond do
				from_identity == nil ->
					conn
					|> put_status(:not_found)
					|> render(Democracy.ErrorView, "error.json", message: "From identity does not exist")
				to_identity == nil ->
					conn
					|> put_status(:not_found)
					|> render(Democracy.ErrorView, "error.json", message: "To identity does not exist")
				true ->
					delegation = Repo.get_by(Delegation, %{from_identity_id: from_identity.id, to_identity_id: to_identity.id, is_last: true})
					if delegation do
						Delegation.unset(from_identity, to_identity)

						conn
						|> send_resp(:no_content, "")
					else
						conn
						|> put_status(:not_found)
						|> render(Democracy.ErrorView, "error.json", message: "Delegation does not exist")
					end
			end
		else
			send_resp(conn, :unauthorized, "Current user should be from user")
		end
	end
end
