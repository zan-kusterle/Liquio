defmodule Democracy.Plugs.TrustMetricIdsParam do
	def handle(conn, url, opts) do
		if url == nil or String.length(url) == 0 do
			identity = Guardian.Plug.current_resource(conn)
			url = if identity != nil and identity.trust_metric_url != nil do
				identity.trust_metric_url
			else
				Democracy.TrustMetric.default_trust_metric_url()
			end
		end
		case Democracy.TrustMetric.get(url) do
			{:ok, trust_identity_ids} ->
				{:ok, trust_identity_ids}
			{:error, message} ->
				{:error, :bad_request, message}
		end
	end
end