defmodule Liquio.HtmlLoginController do
	use Liquio.Web, :controller

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
end