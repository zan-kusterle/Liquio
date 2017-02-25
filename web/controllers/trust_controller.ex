defmodule Liquio.TrustController do
	use Liquio.Web, :controller

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:to_identity => {Plugs.ItemParam, [schema: Identity, name: "identity_id", column: "username"]}
	},
	def create(conn, %{:user => user, :to_identity => to_identity, "is_trusted" => is_trusted}) do
		user |> Identity.set_trust(to_identity, is_trusted)
		
		conn
		|> put_resp_header("location", identity_path(conn, :show, user.id))
		|> send_resp(:created, "")
	end)

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:to_identity => {Plugs.ItemParam, [schema: Identity, name: "identity_id", column: "username"]}
	},
	def delete(conn, %{:user => user, :to_identity => to_identity}) do
		user |> Identity.unset_trust(to_identity)
		
		conn
		|> put_resp_header("location", identity_path(conn, :show, user.id))
		|> send_resp(:no_content, "")
	end)
end