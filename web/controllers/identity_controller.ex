defmodule Liquio.IdentityController do
	use Liquio.Web, :controller

	def index(conn, %{}) do
		identities = Identity |> Repo.all
		render(conn, "index.json", identities: identities)
	end

	plug :scrub_params, "identity" when action in [:create]
	def create(conn, %{"token" => token, "identity" => params}) do
		email = Token.get_email(token)
		if email == nil do
			conn
			|> redirect(to: "/login")
		else
			identity = Identity.create(Identity.changeset(%Identity{email: email}, params))
			Token.use(token)
			conn
			|> Guardian.Plug.sign_in(identity)
			|> redirect(to: "/")
		end
	end

	with_params(%{
		:identity => {Plugs.IdentityParam, [name: "id", column: :username]},
		:user => {Plugs.CurrentUser, [require: false]}
	},
	def show(conn, %{:identity => identity, :user => user}) do
		render(conn, "show.json", identity: identity |> Identity.preload(user))
	end)
end
