defmodule Democracy.UserController do
  use Democracy.Web, :controller

  alias Democracy.User

  plug :scrub_params, "user" when action in [:create, :update]

  def create(conn, %{"user" => user_params}) do
    changeset = User.changeset(%User{
        :username => User.generate_username(),
        :token => User.generate_token()
    }, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", user_path(conn, :show, user))
        |> render("show.json", user: Map.put(user, :insecure_token, user.token))
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Democracy.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => username}) do
      user = Repo.get_by!(User, username: username)
    render(conn, "show.json", user: user)
  end

  def update(conn, %{"id" => username, "user" => user_params}) do
    user = Repo.get_by!(User, username: username)
    changeset = User.changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, user} ->
        render(conn, "show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Democracy.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => username}) do
    user = Repo.get_by!(User, username: username)

    Repo.delete!(user)

    send_resp(conn, :no_content, "")
  end
end
