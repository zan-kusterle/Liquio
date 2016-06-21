defmodule Democracy.Plugs.TrustMetricUrl do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		assign(conn, assign_atom,
			Map.get(conn.params, query_name) || TrustMetric.default_trust_metric_url()
		)
	end
end