defmodule Liquio.HtmlTokenController do
	use Liquio.Web, :controller

	alias Liquio.Token

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
				|> render("new.html", width: 500, token: token, email: email)
			else
				sign_in(conn, identity, token)
			end
		end
	end

	def create(conn, params) do
		email = Token.get_email(params["token"])
		result = Identity.create(Identity.changeset(%Identity{}, params))

		result |> handle_errors(conn, & sign_in(conn, &1, params["token"]))
	end

	defp sign_in(conn, identity, token) do
		Token.use(token)
		conn
		|> Guardian.Plug.sign_in(identity)
		|> put_flash(:info, "Hello, #{identity.name}")
		|> redirect(to: html_identity_path(conn, :show, identity.id))
	end
end