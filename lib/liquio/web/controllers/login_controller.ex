defmodule Liquio.Web.LoginController do
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
			|> render(Liquio.Web.IdentityView, "show.json", identity: Map.put(identity, :access_token, access_token))
		end
	end
	def show(conn, %{"id" => token}) do
		email = Token.get_email(token)
		if email == nil do
			conn
			|> redirect(to: "/login")
		else
			identity = Repo.get_by(Identity, email: email)
			if identity == nil do
				conn
				|> redirect(to: "/login/#{token}/new")
			else
				Token.use(token)
				conn
				|> Guardian.Plug.sign_in(identity)
				|> redirect(to: "/")
			end
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
			|> render(Liquio.Web.IdentityView, "show.json", identity: Map.put(identity, :access_token, access_token))
		else
			conn
			|> send_resp(:unauthorized, "")
		end
	end

	def delete(conn, _params) do
		conn
		|> Guardian.Plug.sign_out
		|> send_resp(:no_content, "")
	end
end
