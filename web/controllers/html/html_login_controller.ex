defmodule Democracy.HtmlLoginController do
	use Democracy.Web, :controller

	alias Democracy.Identity

	def index(conn, _params) do
		conn
		|> render("index.html")
	end

	def create(conn, %{"username" => username, "password" => password}) do
		identity = Repo.get_by(Identity, username: username)
		if identity != nil and identity.token == password do
			conn
			|> put_flash(:info, "Logged in.")
			|> Guardian.Plug.sign_in(identity)
			|> redirect(to: identity_path(conn, :show, identity.id))
		else
			conn
			|> send_resp(:unauthorized, "")
		end	
	end

	def delete(conn, _params) do
		Guardian.Plug.sign_out(conn)
		|> put_flash(:info, "Logged out successfully.")
		|> redirect(to: html_login_path(conn, :create))
	end
end