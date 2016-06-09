defmodule Democracy.LoginController do
	use Democracy.Web, :controller

	alias Democracy.Identity

	plug :scrub_params, "identity" when action in [:create]

	def create(conn, %{"identity" => %{"username" => username, "password" => password}}) do
		identity = Repo.get_by!(Identity, username: username)
		if identity.token == password do
			conn = Guardian.Plug.sign_in(conn, identity)
			access_token = Guardian.Plug.current_token(conn)

			conn
			|> render(Democracy.IdentityView, "show.json", identity: Map.put(identity, :access_token, access_token))
		else
			conn
			|> send_resp(:unauthorized, "")
		end	
	end

	def delete(conn, _params) do
		conn
		|> Guardian.Plug.sign_out(conn)
		|> send_resp(:no_content, "")
	end
end
