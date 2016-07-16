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
			datetime: Timex.DateTime.now,
			trust_metric_ids: MapSet.new(0..100 |> Enum.map(&to_string/1)),
			vote_weight_halving_days: nil,
			soft_quorum_t: 0,
			minimum_reference_approval_score: 0.5
		}

		#def handle(conn, url, opts) do
		#	if url == nil or String.length(url) == 0 do
		#		identity = Guardian.Plug.current_resource(conn)
		#		url = if identity != nil and identity.trust_metric_url != nil do
		#			identity.trust_metric_url
		#		else
		#			Democracy.TrustMetric.default_trust_metric_url()
		#		end
		#	end
		#	case Democracy.TrustMetric.get(url) do
		#		{:ok, trust_identity_ids} ->
		#			{:ok, trust_identity_ids}
		#		{:error, message} ->
		#			{:error, :bad_request, message}
		#	end
		#end
		
		#%{
		#	datetime: conn.params.datetime,
		#	trust_metric_ids: conn.params.trust_metric_ids,
		#	vote_weight_halving_days: conn.params.vote_weight_halving_days || identity.vote_weight_halving_days,
		#	soft_quorum_t: if identity != nil and identity.soft_quorum_t != nil do identity.soft_quorum_t else 1 end,
		#	minimum_reference_approval_score: if identity != nil and identity.minimum_reference_approval_score != nil do identity.minimum_reference_approval_score else 0.5 end,
		#}
	end
end