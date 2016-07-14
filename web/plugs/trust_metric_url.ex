defmodule Democracy.Plugs.TrustMetricIds do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		url = Map.get(conn.params, query_name)
		if url == nil or String.length(url) == 0 do
			url = Democracy.TrustMetric.default_trust_metric_url()
		end
		case TrustMetric.get(url) do
        	{:ok, trust_identity_ids} ->
				%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{assign_atom => url})}
			{:error, message} ->
				conn
				|> put_flash(:error, message)
				|> halt
		end
	end
end