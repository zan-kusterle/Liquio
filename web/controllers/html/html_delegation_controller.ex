defmodule Democracy.HtmlDelegationController do
	use Democracy.Web, :controller
	alias Democracy.Identity
	alias Democracy.Delegation

	plug Democracy.Plugs.Params, [
		{:identity, :user, [require: true]},
		{:item, :identity, [schema: Identity, name: "html_identity_id"]},
		{:number, :weight, [name: "weight", error: "Delegation weight must be a number"]},
		{:topics, :topics, [name: "topics"]}
	] when action in [:create]
	def create(conn, %{:user => from_identity, :identity => to_identity, :weight => weight, :topics => topics}) do
		if weight == 0 do
			Delegation.unset(from_identity, to_identity)
			conn
			|> redirect_back
		else
			Delegation.set(Delegation.changeset(%Delegation{}, %{
				from_identity_id: from_identity.id,
				to_identity_id: to_identity.id,
				weight: weight,
				topics: topics
			})) |> handle_errors(conn, fn(delegation) ->
				conn
				|> redirect_back
			end)
		end
	end
end