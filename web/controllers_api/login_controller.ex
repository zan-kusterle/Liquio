defmodule Liquio.LoginController do
	use Liquio.Web, :controller

	def create(conn, %{"email" => email}) do
		token = Token.new(email)
		Token.send_token(token)

		conn
		|> send_resp(:created, "")
	end

	def show(conn, %{"email" => email}) do
		if Mix.env == :dev do
			identity = Repo.get_by(Identity, email: email)
			conn = Guardian.Plug.sign_in(conn, identity)
			access_token = Guardian.Plug.current_token(conn)

			conn
			|> render(Liquio.IdentityView, "show.json", identity: Map.put(identity, :access_token, access_token))
		end
	end
	def show(conn, %{"token" => token}) do
		email = Token.get_email(token)
		if email != nil do
			identity = Repo.get_by(Identity, email: email)
			Token.use(token)
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
