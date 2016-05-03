defmodule Democracy.SessionController do
    use Democracy.Web, :controller

    alias Democracy.User

    plug :scrub_params, "user" when action in [:create]

    def create(conn, %{"user" => %{"token" => token}}) do
        verified_user = Repo.get_by!(User, token: token)

        conn = Guardian.Plug.sign_in(conn, verified_user)
        access_token = Guardian.Plug.current_token(conn)

        conn
        |> render(Democracy.UserView, "show.json", user: Map.put(verified_user, :access_token, access_token))
    end

    def delete(conn, _params) do
        conn
        |> Guardian.Plug.sign_out(conn)
        |> send_resp(:no_content, "")
    end
end
