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
			|> put_flash(:info, "You no longer delegate your votes to this identity.")
			|> redirect(to: default_redirect(conn))
		else
			current_delegation = Delegation.get_by(from_identity, to_identity)
			current_weight = if current_delegation != nil and current_delegation.data != nil do current_delegation.data.weight else nil end

			weight = weight || 1.0
			changeset = Delegation.changeset(%Delegation{}, %{
				from_identity_id: from_identity.id,
				to_identity_id: to_identity.id,
				weight: weight,
				topics: topics
			})
			
			query = from(d in Delegation, where: d.from_identity_id == ^from_identity.id and d.is_last == true and not is_nil(d.data))
			total_weights = query
			|> Repo.all
			|> Enum.map(& &1.data.weight)
			|> Enum.sum
			next_total = (total_weights - (current_weight || 0) + weight)
			ratio = weight / next_total

			changeset
			|> Delegation.set
			|> handle_errors(conn, fn(_delegation) ->
				conn
				|> put_flash(:info, "You now delegate #{round(100 * ratio)}% of your power for those topics.")
				|> redirect(to: default_redirect(conn))
			end)
		end
	end)
end