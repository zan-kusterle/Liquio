defmodule Democracy.DelegationView do
	use Democracy.Web, :view

	def render("index.json", %{delegations: delegations}) do
		%{data: render_many(delegations, Democracy.DelegationView, "delegation.json")}
	end

	def render("show.json", %{delegation: delegation}) do
		%{data: render_one(delegation, Democracy.DelegationView, "delegation.json")}
	end

	def render("delegation.json", %{delegation: delegation}) do
		%{
			from_identity: Democracy.IdentityView.render("identity.json", identity: delegation.from_identity),
			to_identity: Democracy.IdentityView.render("identity.json", identity: delegation.to_identity),
			weight: delegation.data.weight,
			topics: delegation.data.topics
		}
	end
end
