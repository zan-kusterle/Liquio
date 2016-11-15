defmodule Liquio.HtmlLoginController do
	use Liquio.Web, :controller

	alias Liquio.Token

	def index(conn, _params) do
		conn
		|> render("index.html", width: 500)
	end

	def create(conn, %{"email" => email}) do
		Token.new(email)
		conn
		|> put_flash(:info, "Check your inbox at #{email}")
		|> redirect(to: html_login_path(conn, :index))	
	end

	def delete(conn, _params) do
		conn
		|> Guardian.Plug.sign_out
		|> put_flash(:info, "Goodbye")
		|> redirect(to: html_login_path(conn, :index))
	end
end