defmodule Liquio.HtmlLoginController do
	use Liquio.Web, :controller

	def show(conn, %{"id" => token}) do
		email = Token.get_email(token)
		if email == nil do
			conn
			|> put_flash(:info, "Error logging in, please try again")
			|> redirect(to: html_login_path(conn, :index))
		else
			identity = Repo.get_by(Identity, email: email)
			if identity == nil do
				conn
				|> render(Liquio.LoginView, "new.html", token: token, email: email)
			else
				Token.use(token)
				conn
				|> Guardian.Plug.sign_in(identity)
				|> put_flash(:info, "Hello, #{identity.name}")
				|> redirect(to: "/")
			end
		end
	end
end