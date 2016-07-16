defmodule Democracy.HtmlDelegationController do
	use Democracy.Web, :controller

	with_params(%{
		:from_identity => {Plugs.CurrentUser, []},
		:to_identity => {Plugs.ItemParam, [name: "html_identity_id", schema: Identity]},
		:weight => {Plugs.NumberParam, [name: "weight", error: "Delegation weight must be a number"]},
		:topics => {Plugs.ListParam, [name: "topics", item: {Plugs.StringParam, []}]}
	},
	def create(conn, %{:from_identity => from_identity, :to_identity => to_identity, :weight => weight, :topics => topics}) do
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