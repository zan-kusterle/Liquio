defmodule Liquio.LoginController do
	use Liquio.Web, :controller

	plug :scrub_params, "identity" when action in [:create]

	def create(conn, %{"identity" => %{"username" => username, "password" => password}}) do
		identity = Repo.get_by(Identity, username: username)
		if identity != nil and Comeonin.Bcrypt.checkpw(password, identity.password_hash) do
			conn = Guardian.Plug.sign_in(conn, identity)
			
			access_token = Guardian.Plug.current_token(conn)
			conn
			|> render(Liquio.IdentityView, "show.json", identity: Map.put(identity, :access_token, access_token))
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
