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
			trusts: identity.trusts || Map.new,
			delegations_to: render_many(Map.get(identity, :delegations_to, []), Liquio.Web.DelegationView, "delegation.json") |> Enum.map(& {&1.from_identity.username, &1}) |> Enum.into(%{}),
			delegations: render_many(Map.get(identity, :delegations_from, []), Liquio.Web.DelegationView, "delegation.json") |> Enum.map(& {&1.to_identity.username, &1}) |> Enum.into(%{}),
			votes: render_many(Map.get(identity, :vote_nodes, []), Liquio.Web.NodeView, "node.json")
		}

		v = if Map.has_key?(identity, :access_token) do
			Map.put(v, :access_token, identity.access_token)
		else
			v
		end
		
		v
	end
end
