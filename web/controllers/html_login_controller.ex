defmodule Liquio.HtmlLoginController do
	use Liquio.Web, :controller

	alias Liquio.Token

	def index(conn, _params) do
		conn
		|> render("index.html")
	end

	def create(conn, %{"email" => email}) do
		if Mix.env == :dev do
			identity = Repo.get_by(Identity, email: email)
			identity = if identity do
				identity
			else
				name = case String.split(email, "@", parts: 2) do
					[left, _] ->  left
					[_] -> "dev"
				end
				identity = Identity.create(Identity.changeset(%Identity{email: email}, %{"username" => name, "name" => name}))
			end
			conn
			|> Guardian.Plug.sign_in(identity)
			|> put_flash(:info, "Hello, #{identity.name}")
			|> redirect(to: html_identity_path(conn, :show, identity.id))
		else
			Token.new(email)
			conn
			|> put_flash(:info, "Check your inbox at #{email}")
			|> redirect(to: html_login_path(conn, :index))
		end
	end

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
				|> render("new.html", token: token, email: email)
			else
				Token.use(token)
				conn
				|> Guardian.Plug.sign_in(identity)
				|> put_flash(:info, "Hello, #{identity.name}")
				|> redirect(to: html_identity_path(conn, :show, identity.id))
			end
		end
	end

	def delete(conn, _params) do
		conn
		|> Guardian.Plug.sign_out
		|> put_flash(:info, "Goodbye")
		|> redirect(to: html_login_path(conn, :index))
	end
end