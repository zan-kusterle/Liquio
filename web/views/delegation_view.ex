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
			from_username: delegation.from_identity.username,
			to_username: delegation.to_identity.username,
			weight: delegation.weight,
			topics: delegation.topics
		}
	end
end
