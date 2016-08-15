defmodule Liquio.Controllers.Helpers do
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

	def handle_errors({:error, _changeset}, conn, _func) do
		conn
		|> Phoenix.Controller.put_flash(:error, "Something went wrong")
		|> Phoenix.Controller.redirect(to: default_redirect(conn))
	end

	def handle_errors({:ok, item}, _conn, func) do
		func.(item)
	end

	def get_calculation_opts_from_conn(conn) do
		identity = Guardian.Plug.current_resource(conn)
		now = Timex.DateTime.now
		datetime =
			if Map.has_key?(conn.params, :datetime) do
				param_datetime = Timex.DateTime.shift(conn.params.datetime, days: 1)
				if param_datetime < now do
					param_datetime
				else
					now
				end
			else
				now
			end
		{trust_metric_url, trust_identity_ids} = get_trust_identity_ids(conn)
		
		%{
			datetime: datetime,
			trust_metric_url: trust_metric_url,
			trust_metric_ids: trust_identity_ids,
			vote_weight_halving_days: Map.get(conn.params, :vote_weight_halving_days) || (identity && identity.vote_weight_halving_days) || nil,
			soft_quorum_t: (identity && identity.soft_quorum_t) || 0,
			minimum_reference_approval_score: (identity && identity.minimum_reference_approval_score) ||  0.5,
			minimum_voting_power: (identity && identity.minimum_voting_power) ||  1,
		}
	end

	def get_trust_identity_ids(conn) do
		identity = Guardian.Plug.current_resource(conn)

		url = Map.get(conn.params, :trust_metric_url)
		url =
			if url == nil or String.length(url) == 0 do
				if identity != nil and identity.trust_metric_url != nil do
					identity.trust_metric_url
				else
					Liquio.TrustMetric.default_trust_metric_url()
				end
			else
				url
			end

		case Liquio.TrustMetric.get(url) do
			{:ok, trust_identity_ids} ->
				{url, trust_identity_ids}
			{:error, _reason} ->
				url = Liquio.TrustMetric.default_trust_metric_url()
				{url, Liquio.TrustMetric.get!(url)}
		end
	end
end