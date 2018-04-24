defmodule Liquio.Results do
	alias Liquio.VotingPower
	alias Liquio.Average

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

		_contributions =
			if vote_weight_halving_days == nil do
				contributions
			else
				contributions |> Enum.map(fn(contribution) ->
					Map.put(contribution, :voting_power, contribution.voting_power * moving_average_weight(contribution, datetime, vote_weight_halving_days))
				end)
			end

		%{
			:voting_power => Enum.sum(Enum.map(latest_contributions, & &1.voting_power)),
			:mean => Average.mean(latest_contributions),
			:median => Average.median(latest_contributions),
			:contributions => contributions
		}
	end

	defp moving_average_weight(contribution, reference_datetime, vote_weight_halving_days) do
		ct = contribution.datetime |> Timex.to_erl |> :calendar.datetime_to_gregorian_seconds
		rt = reference_datetime |> Timex.to_erl |> :calendar.datetime_to_gregorian_seconds
		delta_days = (rt - ct) / (24 * 3600)

		:math.pow(0.5, delta_days / vote_weight_halving_days)
	end
end
