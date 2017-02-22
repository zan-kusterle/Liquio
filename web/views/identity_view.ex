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
			id: identity.id,
			username: identity.username,
			name: identity.name,
			trusted_by: [],
			untrusted_by: [],
			delegations_to: [],
			delegations_from: [],
			votes: [],
			vote_nodes: render_many(Map.get(identity, :vote_nodes, []), Liquio.NodeView, "node.json")
		}

		v = if Map.has_key?(identity, :access_token) do
			Map.put(v, :access_token, identity.access_token)
		else
			v
		end
		v
	end
end
