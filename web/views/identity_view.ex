defmodule Liquio.IdentityView do
	use Liquio.Web, :view

	def render("index.json", %{identities: identities}) do
		%{data: render_many(identities, Liquio.IdentityView, "identity.json")}
	end

	def render("show.json", %{identity: identity}) do
		%{data: render_one(identity, Liquio.IdentityView, "identity.json")}
	end

	def render("identity.json", %{identity: identity}) do
		v = %{
			username: identity.username,
			name: identity.name,
			trusts: identity.trusts || Map.new,
			is_trusted: Map.get(identity, :is_trusted),
			own_delegation: if Map.get(identity, :own_delegation) do render_one(identity.own_delegation, Liquio.DelegationView, "delegation.json") else nil end,
			delegations: %{},
			votes: render_many(Map.get(identity, :vote_nodes, []), Liquio.NodeView, "node.json")
		}

		v = if Map.has_key?(identity, :access_token) do
			Map.put(v, :access_token, identity.access_token)
		else
			v
		end
		v
	end
end
