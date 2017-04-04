defmodule Liquio.CalculationOpts do
	alias Liquio.TrustMetric
	
	def get_from_conn(conn) do
		# add sort and pagination

		depth = min((if Map.has_key?(conn.params, "depth") do clean_number(Map.get(conn.params, "depth"), whole: true) else nil end) || 1, 3)
		identity = Guardian.Plug.current_resource(conn)
		now = Timex.now
		datetime =
			if Map.has_key?(conn.params, :datetime) do
				param_datetime = Timex.shift(conn.params.datetime, days: 1, seconds: -1)
				if not Timex.before?(now, param_datetime) do
					param_datetime
				else
					now
				end
			else
				now
			end
		{trust_metric_url, trust_identity_ids} = get_trust_identity_ids(conn)
		trust_metric_count = MapSet.size(trust_identity_ids)
		
		%{
			datetime: datetime,
			depth: depth,
			trust_metric_url: trust_metric_url,
			trust_metric_ids: trust_identity_ids,
			vote_weight_halving_days: Map.get(conn.params, :vote_weight_halving_days),
			reference_minimum_agree: 0.5,
			minimum_voting_power: 0.05 * trust_metric_count,
			minimum_turnout: 0.05,
			reference_minimum_turnout: 0
		}
	end

	defp clean_number(value, opts) do
		if value == nil or String.length(value) == 0 do
			nil
		else
			if opts[:whole] == true do
				case Integer.parse(value) do
					{x, _} -> x
					:error -> nil
				end
			else
				case Float.parse(value) do
					{x, _} -> x
					:error -> nil
				end
			end
		end
	end

	defp get_trust_identity_ids(conn) do
		identity = Guardian.Plug.current_resource(conn)

		url = Map.get(conn.params, :trust_metric_url)
		url =
			if url == nil or not (String.starts_with?(url, "http://") or String.starts_with?(url, "https://")) do
				TrustMetric.default_trust_metric_url()
			else
				url
			end

		case TrustMetric.get(url) do
			{:ok, trust_identity_ids} ->
				{url, trust_identity_ids}
			{:error, _reason} ->
				url = TrustMetric.default_trust_metric_url()
				{url, TrustMetric.get!(url)}
		end
	end
end