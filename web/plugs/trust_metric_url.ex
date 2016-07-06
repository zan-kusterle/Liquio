defmodule Democracy.Plugs.TrustMetricUrl do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		url = Map.get(conn.params, query_name)
		if url == nil or String.length(url) == 0 do
			url = Democracy.TrustMetric.default_trust_metric_url()
		end
		assign(conn, assign_atom, url)
	end
end