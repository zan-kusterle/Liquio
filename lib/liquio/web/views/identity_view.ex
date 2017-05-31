defmodule Liquio.Web.IdentityView do
	use Liquio.Web, :view

	def render("index.json", %{identities: identities}) do
		%{data: render_many(identities, Liquio.Web.IdentityView, "identity.json")}
	end

	def render("show.json", %{identity: identity}) do
		%{data: render_one(identity, Liquio.Web.IdentityView, "identity.json")}
	end

	def render("identity.json", %{identity: identity}) do
		%{
			username: identity.username,
			is_in_trust_metric: true,
			delegations_to: Map.get(identity, :delegations_to, []) |> Enum.map(& {&1.username, render("delegation.json", %{delegation: &1})}) |> Enum.into(%{}),
			delegations: Map.get(identity, :delegations_from, []) |> Enum.map(& {&1.to_username, render("delegation.json", %{delegation: &1})}) |> Enum.into(%{}),
			#votes: render_many(Map.get(identity, :vote_nodes, []), Liquio.Web.NodeView, "node.json")
		}
	end

	def render("delegation.json", %{delegation: delegation}) do
		%{
			from_username: delegation.username,
			to_username: delegation.to_username,
			is_trusting: delegation.is_trusting,
			weight: delegation.weight,
			topics: delegation.topics
		}
	end
end
