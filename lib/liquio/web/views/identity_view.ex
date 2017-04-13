defmodule Liquio.Web.IdentityView do
	use Liquio.Web, :view

	def render("index.json", %{identities: identities}) do
		%{data: render_many(identities, Liquio.Web.IdentityView, "identity.json")}
	end

	def render("show.json", %{identity: identity}) do
		%{data: render_one(identity, Liquio.Web.IdentityView, "identity.json")}
	end

	def render("identity.json", %{identity: identity}) do
		v = %{
			username: identity.username,
			name: identity.name,
			trusts_to: Map.get(identity, :trusts_to, []),
			trusts: Map.get(identity, :trusts_from, []),
			delegations_to: Map.get(identity, :delegations_to, []) |> Enum.map(& {&1.from_identity.username, render("delegation.json", %{delegation: &1})}) |> Enum.into(%{}),
			delegations: Map.get(identity, :delegations_from, []) |> Enum.map(& {&1.to_identity.username, render("delegation.json", %{delegation: &1})}) |> Enum.into(%{}),
			votes: render_many(Map.get(identity, :vote_nodes, []), Liquio.Web.NodeView, "node.json")
		}

		v = if Map.has_key?(identity, :access_token) do
			Map.put(v, :access_token, identity.access_token)
		else
			v
		end
		
		v
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
