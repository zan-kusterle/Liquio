defmodule Liquio.Results.AggregateContributions do
	def aggregate(contributions, %{:datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		choice_type = if Enum.empty?(contributions) do nil else Enum.at(contributions, 0).choice_type end
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))
		trust_metric_size = MapSet.size(trust_metric_ids)

		by_keys = contributions
		|> Enum.flat_map(fn(contribution) ->
			Enum.map(contribution.choice, fn({key, choice}) ->
				%{
					:key => key,
					:choice => choice,
					:default_value => if is_number(choice) do choice else choice[key] end,
					:voting_power => contribution.voting_power,
					:datetime => contribution.datetime
				}
			end)
		end)
		|> Enum.group_by(& &1.key)
		|> Enum.map(fn({key, contributions_for_key}) ->
			{key, aggregate_for_key(contributions_for_key, datetime, vote_weight_halving_days, choice_type, trust_metric_size)}
		end)
		|> Enum.into(%{})

		results = %{
			:total => total_power,
			:turnout_ratio => if trust_metric_size == 0 do 0 else total_power / trust_metric_size end,
			:count => Enum.count(contributions),
			:by_keys => by_keys,
			:choice_type => choice_type
		}
		
		results = if choice_type == "time_quantity" do
			results_with_datetime = results.by_keys
			|> Enum.map(fn({time_key, time_results}) ->
				case Integer.parse(time_key) do
					{year, ""} -> Map.put(time_results, :datetime, Timex.to_date({year, 1, 1}))
					:error -> nil
				end
			end)
			|> Enum.filter(& &1 != nil)
			results |> Map.put(:by_datetime, results_with_datetime)
		else
			results
		end

		results
	end

	def by_key(aggregations_by_key, key) do
		Map.get(aggregations_by_key, key, empty())
	end

	def empty() do
		%{
			:mean => nil,
			:total => 0,
			:turnout_ratio => 0,
			:count => 0
		}
	end

	defp aggregate_for_key(contributions_for_key, datetime, vote_weight_halving_days, choice_type, trust_metric_size) do
		key_total_power = Enum.sum(Enum.map(contributions_for_key, & &1.voting_power))

		adjusted_contributions =
			if vote_weight_halving_days == nil do
				contributions_for_key
			else
				contributions_for_key |> Enum.map(fn(contribution) ->
					Map.put(contribution, :voting_power, contribution.voting_power * moving_average_weight(contribution, datetime, vote_weight_halving_days))
				end)
			end
		mean =
			if choice_type == "probability" do
				mean(adjusted_contributions)
			else
				median(adjusted_contributions)
			end

		%{
			:mean => mean,
			:total => round(key_total_power),
			:turnout_ratio => if trust_metric_size == 0 do 0 else key_total_power / trust_metric_size end,
			:count => Enum.count(contributions_for_key)
		}
	end

	defp mean(contributions) do
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))
		total_score = Enum.sum(Enum.map(contributions, fn(contribution) ->
			contribution.default_value * contribution.voting_power
		end))
		if total_power > 0 do
			1.0 * total_score / total_power
		else
			nil
		end
	end

	defp median(contributions) do
		contributions = contributions |> Enum.sort(&(&1.choice > &2.choice))
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))
		if total_power > 0 do
			Enum.reduce_while(contributions, 0.0, fn(contribution, current_power) ->
				if current_power + contribution.voting_power > total_power / 2 do
					{:halt, 1.0 * contribution.choice}
				else
					{:cont, current_power + contribution.voting_power}
				end
			end)
		else
			nil
		end
	end

	defp moving_average_weight(contribution, reference_datetime, vote_weight_halving_days) do
		ct = contribution.datetime |> Timex.to_erl |> :calendar.datetime_to_gregorian_seconds
		rt = reference_datetime |> Timex.to_erl |> :calendar.datetime_to_gregorian_seconds
		delta_days = (rt - ct) / (24 * 3600)

		:math.pow(0.5, delta_days / vote_weight_halving_days)
	end
end