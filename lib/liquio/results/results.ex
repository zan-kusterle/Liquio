defmodule Liquio.Results do
	alias Liquio.{Node, VotingPower, Repo, Vote, ResultsEmbeds}

	def from_votes(votes) do from_votes(votes, %{}) end
	def from_votes(votes, inverse_delegations) do
		from_votes(votes, inverse_delegations, %{:datetime => Timex.now, :topics => nil})
	end
	def from_votes(votes, inverse_delegations, %{:datetime => datetime, :topics => topics}) do
		votes = votes
		|> Enum.map(& &1 |> Map.put(:at_date, Map.get(&1, :at_date, datetime)))

		active_trust_usernames = votes |> Enum.map(& &1.username) |> MapSet.new

		topics = if is_list(topics) do MapSet.new(topics) else topics end
		inverse_delegations = inverse_delegations |> Enum.filter(fn({from_identity_username, _}) ->
			not MapSet.member?(active_trust_usernames, from_identity_username) and
			(topics == nil or not MapSet.disjoint?(topics, MapSet.new))
		end) |> Enum.into(%{})
		power_by_usernames = VotingPower.get(active_trust_usernames, inverse_delegations)
		total_voting_power = power_by_usernames |> Enum.map(fn({_, power}) -> power end) |> Enum.sum
		contributions = votes |> Enum.map(fn(vote) ->
			power = Map.get(power_by_usernames, vote.username, 0)
			vote
			|> Map.put(:voting_power, power)
			|> Map.put(:weight, if total_voting_power > 0 do power / total_voting_power else 0 end)
		end)

		from_contributions(contributions, datetime)		
	end

	defp from_contributions(contributions, datetime) do
		contributions = contributions |> Enum.sort_by(& Timex.to_unix(&1.at_date))
		contributions_by_identities = contributions |> Enum.group_by(& &1.username)
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

		%{
			:voting_power => Enum.sum(Enum.map(latest_contributions, & &1.voting_power)),
			:mean => mean(latest_contributions),
			:median => median(latest_contributions),
			:latest_contributions => latest_contributions,
			:contributions_by_identities => contributions_by_identities |> Enum.map(fn({key, contributions_for_identity}) ->
				contributions_for_identity = contributions_for_identity |> Enum.sort_by(& Timex.to_unix(&1.at_date))
				{key, contributions_for_identity}
			end) |> Enum.into(%{})
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