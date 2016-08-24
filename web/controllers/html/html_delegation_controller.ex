defmodule Liquio.HtmlDelegationController do
	use Liquio.Web, :controller

	with_params(%{
		:from_identity => {Plugs.CurrentUser, [require: true]},
		:to_identity => {Plugs.ItemParam, [name: "html_identity_id", schema: Identity]},
		:weight => {Plugs.NumberParam, [name: "weight", maybe: true, error: "Delegation weight must be a number"]},
		:topics => {Plugs.ListParam, [name: "topics", maybe: true, item: {Plugs.StringParam, [downcase: true]}]}
	},
	def create(conn, %{:from_identity => from_identity, :to_identity => to_identity, :weight => weight, :topics => topics}) do
		if weight == 0 do
			Delegation.unset(from_identity, to_identity)
			conn
			|> redirect(to: default_redirect(conn))
		else
			changeset = Delegation.changeset(%Delegation{}, %{
				from_identity_id: from_identity.id,
				to_identity_id: to_identity.id,
				weight: weight || 1.0,
				topics: topics
			})
			changeset
			|> Delegation.set
			|> handle_errors(conn, fn(_delegation) ->
				conn
				|> redirect(to: default_redirect(conn))
			end)
		end
	end)
end