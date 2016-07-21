defmodule Democracy.Controllers.Helpers do
	def default_redirect(conn) do
		if Map.get(conn.params, "redirect") do
			conn.params["redirect"]
		else
			case List.keyfind(conn.req_headers, "referer", 0) do
				{"referer", referer} ->
					url = URI.parse(referer)
					url.path
				nil ->
					"/"
			end
		end
	end

	def handle_errors({:error, changeset}, conn, _func) do
		conn
		|> Phoenix.Controller.put_flash(:error, "Couldn't create identity")
		|> Phoenix.Controller.redirect to: "/"
	end

	def handle_errors({:ok, item}, _conn, func) do
		func.(item)
	end

	def get_calculation_opts_from_conn(conn) do
		identity = Guardian.Plug.current_resource(conn)
		%{
			datetime: Map.get(conn.params, :datetime) || Timex.DateTime.now,
			trust_metric_ids: get_trust_identity_ids(conn),
			vote_weight_halving_days: Map.get(conn.params, :vote_weight_halving_days) || (identity && identity.vote_weight_halving_days) || nil,
			soft_quorum_t: (identity && identity.soft_quorum_t) || 0,
			minimum_reference_approval_score: (identity && identity.minimum_reference_approval_score) ||  0.5,
			minimum_voting_power: (identity && identity.minimum_voting_power) ||  1,
		}
	end

	defp get_trust_identity_ids(conn) do
		identity = Guardian.Plug.current_resource(conn)

		url = Map.get(conn.params, :trust_metric_url)
		if url == nil or String.length(url) == 0 do
			url = if identity != nil and identity.trust_metric_url != nil do
				identity.trust_metric_url
			else
				Democracy.TrustMetric.default_trust_metric_url()
			end
		end

		case Democracy.TrustMetric.get(url) do
			{:ok, trust_identity_ids} ->
				trust_identity_ids
			{:error, message} ->
				Democracy.TrustMetric.get!(Democracy.TrustMetric.default_trust_metric_url())
		end
	end
end