defmodule Liquio.Results do
	alias Liquio.{Node, CalculateResults, Repo, Vote, ResultsEmbeds}

	def from_votes(votes) do from_votes(votes, %{}) end
	def from_votes(votes, inverse_delegations) do
		trust_metric_ids = votes |> Enum.map(& &1.identity.username) |> MapSet.new
		from_votes(votes, inverse_delegations, %{:datetime => Timex.now, :trust_metric_ids => trust_metric_ids, :topics => nil})
	end
	def from_votes(votes, inverse_delegations, %{:datetime => datetime, :trust_metric_ids => trust_metric_ids, :topics => topics}) do
		votes = votes |> Repo.preload([:identity])
		by_units = votes |> Enum.group_by(& &1.unit) |> Enum.map(fn({unit_value, votes_for_unit}) ->
			unit = Vote.decode_unit!(unit_value)

			votes_for_unit = if unit.type == :spectrum do
				Enum.filter(votes_for_unit, & &1.choice >= 0.0 and &1.choice <= 1.0)
			else
				votes_for_unit
			end

			power_by_usernames = CalculateResults.power_by_identities(Enum.map(votes_for_unit, & &1.identity), inverse_delegations, trust_metric_ids, topics)
			total_voting_power = power_by_usernames |> Enum.map(fn({_, power}) -> power end) |> Enum.sum
			contributions = votes_for_unit |> Enum.map(fn(vote) ->
				power = Map.get(power_by_usernames, vote.identity.username, 0)
				vote
				|> Map.put(:voting_power, power)
				|> Map.put(:weight, if total_voting_power > 0 do power / total_voting_power else 0 end)
			end)

			unit_results = from_contributions(contributions, datetime, MapSet.size(trust_metric_ids), unit)
			|> Map.put(:unit, unit)
			
			{unit.key, unit_results}
		end) |> Enum.into(%{})

		%{
			:total => 0.0,
			:turnout_ratio => 0.0,
			:by_units => by_units
		}
	end

	def from_reference_votes(votes) do from_reference_votes(votes, %{}) end
	def from_reference_votes(votes, inverse_delegations) do
		trust_metric_ids = votes |> Enum.map(& &1.identity.username) |> MapSet.new
		from_reference_votes(votes, inverse_delegations, %{:datetime => Timex.now, :trust_metric_ids => trust_metric_ids, :topics => nil})
	end
	def from_reference_votes(votes, inverse_delegations, %{:datetime => datetime, :trust_metric_ids => trust_metric_ids}) do
		votes = votes
		|> Repo.preload([:identity])
		|> Enum.map(& &1 |> Map.put(:choice, &1.relevance) |> Map.put(:at_date, &1.datetime))
		|> Enum.filter(& &1.choice >= 0.0 and &1.choice <= 1.0)
		
		power_by_usernames = CalculateResults.power_by_identities(Enum.map(votes, & &1.identity), inverse_delegations, trust_metric_ids, nil)
		total_voting_power = power_by_usernames |> Enum.map(fn({_, power}) -> power end) |> Enum.sum

		contributions = votes |> Enum.map(fn(vote) ->
			power = Map.get(power_by_usernames, vote.identity.username, 0)
			vote
			|> Map.put(:voting_power, power)
			|> Map.put(:weight, if total_voting_power > 0 do power / total_voting_power else nil end)
		end)

		from_contributions(contributions, datetime, MapSet.size(trust_metric_ids), %{:type => :spectrum, :positive => "Relevant", :negative => "Irrelevant"})
	end

	defp from_contributions(contributions, datetime, trust_metric_size, unit) do
		contributions = contributions |> Enum.sort_by(& Timex.to_unix(&1.at_date))
		contributions_by_identities = contributions |> Enum.group_by(& &1.identity_id)
		latest_contributions = contributions_by_identities |> Enum.map(fn({_, cs}) -> cs |> List.last end)

		vote_weight_halving_days = nil

		time_weighted_contributions =
			if vote_weight_halving_days == nil do
				contributions
			else
				contributions |> Enum.map(fn(contribution) ->
					Map.put(contribution, :voting_power, contribution.voting_power * moving_average_weight(contribution, datetime, vote_weight_halving_days))
				end)
			end
		aggregator = if unit.type == :spectrum do &mean/1 else &median/1 end
		average = aggregator.(latest_contributions)
		total_power = Enum.sum(Enum.map(latest_contributions, & &1.voting_power))

		%{
			:total => total_power,
			:turnout_ratio => if trust_metric_size == 0 do 0 else total_power / trust_metric_size end,
			:count => Enum.count(latest_contributions),
			:average => average,
			:latest_contributions => latest_contributions,
			:contributions_by_identities => contributions_by_identities |> Enum.map(fn({key, contributions_for_identity}) ->
				contributions_for_identity = contributions_for_identity |> Enum.sort_by(& Timex.to_unix(&1.at_date))
				{key, %{
					:contributions => contributions_for_identity |> Enum.map(fn(c) ->
						c |> Map.put(:embeds, %{
							:spectrum => if unit.type == :spectrum do ResultsEmbeds.inline_results_spectrum(c.choice, unit) else nil end,
							:value => ResultsEmbeds.inline_results_quantity(c.choice, unit)
						})
					end),
					:embeds => %{
						:by_time => ResultsEmbeds.inline_identity_contributions_by_time(contributions_for_identity)
					}
				}}
			end) |> Enum.into(%{}),
			:embeds => %{
				:spectrum => if unit.type == :spectrum do ResultsEmbeds.inline_results_spectrum(average, unit) else nil end,
				:value => ResultsEmbeds.inline_results_quantity(average, unit),
				:distribution => if unit.type == :spectrum do ResultsEmbeds.inline_results_distribution(latest_contributions, aggregator) else nil end,
				:by_time => ResultsEmbeds.inline_results_by_time(contributions, aggregator)
			}
		}
	end

	defp mean(contributions) do
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))
		total_score = Enum.sum(Enum.map(contributions, fn(contribution) ->
			contribution.choice * contribution.voting_power
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