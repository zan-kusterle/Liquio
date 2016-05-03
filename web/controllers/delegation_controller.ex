import Ecto.Query, only: [from: 2]

defmodule Democracy.DelegationController do
  use Democracy.Web, :controller
  use Guardian.Phoenix.Controller

  alias Democracy.User
  alias Democracy.Delegation

  plug :scrub_params, "delegation" when action in [:create, :update]

  def index(conn, %{"user_id" => from_user_username}, user, claims) do
        from_user = Repo.get_by!(User, username: from_user_username)

        query = from d in Delegation,
            where: d.from_user_id == ^from_user.id,
            select: d
        delegations = Repo.all(query) |> Repo.preload([:from_user, :to_user])

        render(conn, "index.json", delegations: delegations)
  end

  def create(conn, %{"user_id" => from_user_username, "delegation" => %{"to_user_id" => to_user_username, "weight" => weight}}, user, claims) do
        from_user = Repo.get_by!(User, username: from_user_username)
        to_user = Repo.get_by!(User, username: to_user_username)

        if user.id == from_user.id do
            changeset = Delegation.changeset(%Delegation{
                from_user_id: from_user.id,
                to_user_id: to_user.id,
                weight: weight / 1
            }, %{})

            case Repo.insert(changeset) do
              {:ok, delegation} ->
                  delegation = Repo.preload delegation, :from_user
                  delegation = Repo.preload delegation, :to_user
                conn
                |> put_status(:created)
                |> put_resp_header("location", user_delegation_path(conn, :show, from_user, delegation))
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
