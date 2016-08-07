defmodule Liquio.HtmlLoginController do
	use Liquio.Web, :controller

	def index(conn, _params) do
		conn
		|> render("index.html")
	end

	def create(conn, %{"username" => username, "password" => password}) do
		identity = Repo.get_by(Identity, username: username)
		if identity != nil and Comeonin.Bcrypt.checkpw(password, identity.password_hash) do
			conn
			|> put_flash(:info, "Hello, #{identity.name}")
			|> Guardian.Plug.sign_in(identity)
			|> redirect(to: html_identity_path(conn, :show, identity.id))
		else
			conn
			|> put_flash(:error, "Wrong username or password")
			|> redirect(to: html_login_path(conn, :index))
		end	
	end

	def delete(conn, _params) do
		Guardian.Plug.sign_out(conn)
		|> put_flash(:info, "Goodbye")
		|> redirect(to: html_login_path(conn, :create))
	end
end