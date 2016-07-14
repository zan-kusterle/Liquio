defmodule Democracy.Plugs.TrustMetricIdsParam do
	def handle(conn, opts) do
		url = Map.get(conn.params, opts[:name])
		if url == nil or String.length(url) == 0 do
			url = Democracy.TrustMetric.default_trust_metric_url()
		end
		case Democracy.TrustMetric.get(url) do
			{:ok, trust_identity_ids} ->
				{:ok, trust_identity_ids}
			{:error, message} ->
				{:error, :bad_request, message}
		end
	end
end