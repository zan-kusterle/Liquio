defmodule Liquio.Results do
	alias Liquio.{Node, VotingPower, Repo, Vote, ResultsEmbeds}

	def from_votes(votes) do from_votes(votes, %{}) end
	def from_votes(votes, inverse_delegations) do
		trust_usernames = votes |> Enum.map(& &1.identity.username) |> MapSet.new
		from_votes(votes, inverse_delegations, %{:datetime => Timex.now, :trust_usernames => trust_usernames, :topics => nil})
	end
	def from_votes(votes, inverse_delegations, %{:datetime => datetime, :trust_usernames => trust_usernames, :topics => topics}) do
		votes = votes |> Repo.preload([:identity])
		by_units = votes |> Enum.group_by(& &1.unit) |> Enum.map(fn({unit_value, votes_for_unit}) ->
			unit = Vote.decode_unit!(unit_value)

			votes_for_unit = if unit.type == :spectrum do
				Enum.filter(votes_for_unit, & &1.choice >= 0.0 and &1.choice <= 1.0)
			else
				votes_for_unit
			end

			trusted_identities = votes_for_unit
			|> Enum.filter(& MapSet.member?(trust_usernames, &1.identity.username))
			|> Enum.map(& &1.identity)
			topics = if is_list(topics) do MapSet.new(topics) else topics end
			inverse_delegations = inverse_delegations |> Enum.filter(fn({from_identity_username, _}) ->
				MapSet.member?(trust_usernames, from_identity_username) and
				Enum.find(trusted_identities, & &1.username == from_identity_username) == nil and
				(topics == nil or  MapSet.new == nil or not MapSet.disjoint?(topics, MapSet.new))
			end) |> Enum.into(%{})
			power_by_usernames = VotingPower.get(trusted_identities, inverse_delegations)
			total_voting_power = power_by_usernames |> Enum.map(fn({_, power}) -> power end) |> Enum.sum
			contributions = votes_for_unit |> Enum.map(fn(vote) ->
				power = Map.get(power_by_usernames, vote.identity.username, 0)
				vote
				|> Map.put(:voting_power, power)
				|> Map.put(:weight, if total_voting_power > 0 do power / total_voting_power else 0 end)
			end)

			unit_results = from_contributions(contributions, datetime, MapSet.size(trust_usernames), unit)
			|> Map.put(:unit, unit)
			
			{unit.key, unit_results}
		end) |> Enum.into(%{})

		%{
			:voting_power => by_units |> Enum.map(fn({_, v}) -> v.voting_power end) |> Enum.sum,
			:turnout_ratio => by_units |> Enum.map(fn({_, v}) -> v.turnout_ratio end) |> Enum.sum,
			:by_units => by_units
		}
	end

	def from_reference_votes(votes) do from_reference_votes(votes, %{}) end
	def from_reference_votes(votes, inverse_delegations) do
		trust_usernames = votes |> Enum.map(& &1.identity.username) |> MapSet.new
		from_reference_votes(votes, inverse_delegations, %{:datetime => Timex.now, :trust_usernames => trust_usernames, :topics => nil})
	end
	def from_reference_votes(votes, inverse_delegations, %{:datetime => datetime, :trust_usernames => trust_usernames}) do
		votes = votes
		|> Repo.preload([:identity])
		|> Enum.map(& &1 |> Map.put(:choice, &1.relevance) |> Map.put(:at_date, &1.datetime))
		|> Enum.filter(& &1.choice >= 0.0 and &1.choice <= 1.0)
		
		trusted_identities_with_votes = votes
		|> Enum.filter(& MapSet.member?(trust_usernames, &1.identity.username))
		|> Enum.map(& &1.identity)
		inverse_delegations = inverse_delegations |> Enum.filter(fn({from_identity_username, _}) ->
			MapSet.member?(trust_usernames, from_identity_username) and
			Enum.find(trusted_identities_with_votes, & &1.username == from_identity_username) == nil
		end) |> Enum.into(%{})
		power_by_usernames = VotingPower.get(trusted_identities_with_votes, inverse_delegations)
		total_voting_power = power_by_usernames |> Enum.map(fn({_, power}) -> power end) |> Enum.sum

		contributions = votes |> Enum.map(fn(vote) ->
			power = Map.get(power_by_usernames, vote.identity.username, 0)
			vote
			|> Map.put(:voting_power, power)
			|> Map.put(:weight, if total_voting_power > 0 do power / total_voting_power else nil end)
		end)

		from_contributions(contributions, datetime, MapSet.size(trust_usernames), %{:type => :spectrum, :positive => "Relevant", :negative => "Irrelevant"})
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
			:voting_power => total_power,
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
				:distribution => if unit.type == :spectrum do ResultsEmbeds.inline_results_distribution(latest_contributions) else nil end,
				:by_time => ResultsEmbeds.inline_results_by_time(contributions, aggregator)
			}
		}
	end

	defp mean(contributions) do
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))
		total_power = if total_power > 0 do total_power else Enum.count(contributions) end
		total_score = Enum.sum(Enum.map(contributions, fn(contribution) ->
			contribution.choice * contribution.voting_power
		end))
		if total_power == 0 do
			nil
		else
			1.0 * total_score / total_power
		end
	end

	defp median(contributions) do
		contributions = contributions |> Enum.sort(&(&1.choice > &2.choice))
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))
		total_power = if total_power > 0 do total_power else Enum.count(contributions) end

		if total_power == 0 do
			nil
		else
			Enum.reduce_while(contributions, 0.0, fn(contribution, current_power) ->
				if current_power + contribution.voting_power > total_power / 2 do
					{:halt, 1.0 * contribution.choice}
				else
					{:cont, current_power + contribution.voting_power}
				end
			end)
		end
	end

	defp moving_average_weight(contribution, reference_datetime, vote_weight_halving_days) do
		ct = contribution.datetime |> Timex.to_erl |> :calendar.datetime_to_gregorian_seconds
		rt = reference_datetime |> Timex.to_erl |> :calendar.datetime_to_gregorian_seconds
		delta_days = (rt - ct) / (24 * 3600)

		:math.pow(0.5, delta_days / vote_weight_halving_days)
	end
end