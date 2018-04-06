defmodule Liquio.CalculationOpts do
	alias Liquio.TrustMetric
	
	def get_from_conn(conn) do
		# add sort and pagination

		depth = min((if Map.has_key?(conn.params, "depth") do clean_number(Map.get(conn.params, "depth"), whole: true) else nil end) || 1, 3)
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
		metric_trust_usernames = MapSet.new []
		trust_usernames = if Map.has_key?(conn.params, "trust_usernames") do
			force_usernames = conn.params["trust_usernames"] |> String.split(",") |> Enum.filter(& String.length(&1) > 0)
			metric_trust_usernames |> MapSet.union(MapSet.new(force_usernames))
		else
			metric_trust_usernames
		end
		trust_metric_count = MapSet.size(trust_usernames)
		
		%{
			datetime: datetime,
			depth: depth,
			trust_metric_url: "",
			metric_trust_usernames: metric_trust_usernames,
			trust_usernames: trust_usernames,
			vote_weight_halving_days: Map.get(conn.params, :vote_weight_halving_days),
			reference_minimum_agree: 0.5,
			minimum_voting_power: 0.05 * trust_metric_count,
			minimum_turnout: 0.05,
			reference_minimum_turnout: 0
		}
	end

	defp clean_number(value, opts) do
		if is_number(value) do
			if opts[:whole] do
				round(value)
			else
				value
			end
		else
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
	end
end