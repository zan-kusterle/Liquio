defmodule Liquio.TrustController do
	use Liquio.Web, :controller

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:to_identity => {Plugs.ItemParam, [schema: Identity, name: "id"]}
	},
	def create(conn, %{:user => user, :to_identity => to_identity, "trust" => trust_param}) do
		user |> Identity.set_trust(to_identity, trust_param == 1)
		
		conn
		|> put_status(:created)
		|> put_resp_header("location", identity_path(conn, :show, user.id))
	end)

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:to_identity => {Plugs.ItemParam, [schema: Identity, name: "id"]}
	},
	def delete(conn, %{:user => user, :to_identity => to_identity}) do
		user |> Identity.unset_trust(to_identity)
		
		conn
		|> put_status(:no_content)
		|> put_resp_header("location", identity_path(conn, :show, user.id))
	end)
end