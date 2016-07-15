defmodule Democracy.HtmlDelegationController do
	use Democracy.Web, :controller

	with_params([
		{Plugs.CurrentUser, :user, [require: true]},
		{Plugs.ItemParam, :identity, [schema: Identity, name: "html_identity_id"]},
		{Plugs.NumberParam, :weight, [name: "weight", error: "Delegation weight must be a number"]},
		{Plugs.TopicsParam, :topics, [name: "topics"]}
	],
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
	end)
end