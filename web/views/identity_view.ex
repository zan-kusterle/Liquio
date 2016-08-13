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
			trust_metric_poll_id: identity.trust_metric_poll_id
		}
		if Map.has_key?(identity, :insecure_password) do
			v = Map.put(v, :password, identity.insecure_password)
		end
		if Map.has_key?(identity, :access_token) do
			v = Map.put(v, :access_token, identity.access_token)
		end
		if is_list(identity.trust_metric_poll_votes) do
			votes_by_choice = identity.trust_metric_poll_votes
				|> Enum.filter(&(&1.data != nil and &1.is_last))
				|> Enum.group_by(& &1.data.score == 1)
			v = Map.put(v, :trusted_by, Map.get(votes_by_choice, true, []) |> Enum.map(& &1.identity_id))
			v = Map.put(v, :untrusted_by, Map.get(votes_by_choice, false, []) |> Enum.map(& &1.identity_id))
		end
		v
	end
end
