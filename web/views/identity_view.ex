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
			trusted_by_ids: [] 
		}
		v = if Map.has_key?(identity, :insecure_password) do
			Map.put(v, :password, identity.insecure_password)
		else
			v
		end
		v = if Map.has_key?(identity, :access_token) do
			Map.put(v, :access_token, identity.access_token)
		else
			v
		end
		v = if is_list(identity.trust_metric_node_votes) do
			votes_by_choice = identity.trust_metric_node_votes
				|> Enum.filter(&(&1.data != nil and &1.is_last))
				|> Enum.group_by(& &1.data.choice["main"] == 1)
			v
			|> Map.put(:trusted_by, votes_by_choice |> Map.get(true, []) |> Enum.map(& &1.identity_id))
			|> Map.put(:untrusted_by, votes_by_choice |> Map.get(false, []) |> Enum.map(& &1.identity_id))
		else
			v
		end
		v
	end
end
