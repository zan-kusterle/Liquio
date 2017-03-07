defmodule Liquio.Web.DelegationView do
	use Liquio.Web, :view

	def render("index.json", %{delegations: delegations}) do
		%{data: render_many(delegations, Liquio.Web.DelegationView, "delegation.json")}
	end

	def render("show.json", %{delegation: delegation}) do
		%{data: render_one(delegation, Liquio.Web.DelegationView, "delegation.json")}
	end

	def render("delegation.json", %{delegation: delegation}) do
		%{
			from_identity: Liquio.Web.IdentityView.render("identity.json", identity: delegation.from_identity),
			to_identity: Liquio.Web.IdentityView.render("identity.json", identity: delegation.to_identity),
			weight: delegation.data.weight,
			topics: delegation.data.topics
		}
	end
end