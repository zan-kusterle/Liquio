defmodule Democracy.IdentityView do
	use Democracy.Web, :view

	def render("index.json", %{identities: identities}) do
		%{data: render_many(identities, Democracy.IdentityView, "identity.json")}
	end

	def render("show.json", %{identity: identity}) do
		%{data: render_one(identity, Democracy.IdentityView, "identity.json")}
	end

	def render("identity.json", %{identity: identity}) do
		v = %{
			id: identity.id,
			username: identity.username,
			name: identity.name,
			trust_metric_poll_id: identity.trust_metric_poll_id
		}
		if Map.has_key?(identity, :insecure_token) do
			v = Map.put(v, :password, identity.insecure_token)
		end
		if Map.has_key?(identity, :access_token) do
			v = Map.put(v, :access_token, identity.access_token)
		end
		v
	end
end
