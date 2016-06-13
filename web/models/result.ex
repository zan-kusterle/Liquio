defmodule Democracy.Result do
	use Democracy.Web, :model

	alias Democracy.Repo

	schema "results" do
		belongs_to :poll, Democracy.Poll
		field :trust_metric_key, :string
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :data, :map
	end

	def calculate(poll, trust_metric_key, datetime) do
		{delegations, inverse_delegations} = get_delegations(poll, trust_metric_key, datetime)
		votes = get_votes(poll, trust_metric_key, datetime)

		IO.inspect delegations
		IO.inspect inverse_delegations
		IO.inspect votes

		contributions = Enum.map(votes, fn({identity_id, data}) ->
			own_weight = get_power(identity_id, delegations, inverse_delegations, votes)
			Enum.map(data, fn({choice, score}) ->
				%{
					choice: choice,
					identity_id: identity_id,
					weight: own_weight,
					score: score
				}
			end)
		end) |> List.flatten

		contributions_by_choice = contributions |> Enum.group_by(&(&1.choice))

		Enum.map(poll.choices, fn(choice) ->
			contributions_for_choice = Map.get(contributions_by_choice, choice, [])

			count = Enum.count(contributions_for_choice)
			contributions_by_identities = Enum.map(contributions_for_choice, fn(contribution) ->
				%{
					:identity_id => contribution.identity_id,
					:contribution => contribution.weight * contribution.score
				}
			end)
			total = Enum.sum(Enum.map(contributions_by_identities, & &1.contribution))
			mean = total / count
			
			%{
				:choice => choice,
				:mean => mean,
				:total => total,
				:count => count,
				:contributions_by_identities => contributions_by_identities
			}
		end)
	end

	def get_power(identity_id, delegations, inverse_delegations, votes) do
		receiving = inverse_delegations |> Map.get(identity_id, %{}) |> Enum.map(fn({from_identity_id, from_weight}) ->
			if Map.has_key?(votes, from_identity_id) do
				0
			else
				from_power = get_power(from_identity_id, delegations, inverse_delegations, votes)
				total_weight = delegations[from_identity_id] |> Map.values |> Enum.sum
				from_power * (from_weight / total_weight)
			end
		end) |> Enum.sum
		1 + receiving
	end

	def get_delegations(poll, trust_metric_key, datetime) do
		query = "SELECT DISTINCT ON (from_identity_id, to_identity_id) from_identity_id, to_identity_id, data
			FROM delegations
			JOIN trust_metrics AS ta ON ta.key = '#{trust_metric_key}' AND from_identity_id = ta.identity_id
			JOIN trust_metrics AS tb ON tb.key = '#{trust_metric_key}' AND to_identity_id = tb.identity_id
			WHERE datetime <= '#{Ecto.DateTime.to_iso8601(datetime)}'
			ORDER BY from_identity_id, to_identity_id, datetime DESC;"
		result = Ecto.Adapters.SQL.query!(Repo, query , [])
		rows = result.rows |> Enum.filter(fn(r) ->
			data = Enum.at(r, 2)
			if data == nil do
				false
			else
				ta = data["topics"]
				tb = poll.topics
				ta == nil or tb == nil or Enum.any?(ta, &(Enum.member?(tb, &1)))
			end
		end)
		delegations = for {from_identity_id, from_identity_rows} <- rows |> Enum.group_by(&(&1 |> Enum.at 0)), into: %{}, do: {
			from_identity_id,
			(for row <- from_identity_rows, into: %{}, do: {Enum.at(row, 1), Enum.at(row, 2)["weight"]})
		}
		inverse_delegations = for {to_identity_id, to_identity_rows} <- rows |> Enum.group_by(&(&1 |> Enum.at 1)), into: %{}, do: {
			to_identity_id,
			(for row <- to_identity_rows, into: %{}, do: {Enum.at(row, 0), Enum.at(row, 2)["weight"]})
		}
		{delegations, inverse_delegations}
	end

	def get_votes(poll, trust_metric_key, datetime) do
		query = "SELECT DISTINCT ON (v.identity_id) v.identity_id, v.data
			FROM votes AS v
			JOIN trust_metrics AS t ON t.key = '#{trust_metric_key}' AND v.identity_id = t.identity_id
			WHERE v.poll_id = #{poll.id} AND v.datetime <= '#{Ecto.DateTime.to_iso8601(datetime)}'
			ORDER BY v.identity_id, v.datetime DESC;"
		result = Ecto.Adapters.SQL.query!(Repo, query , [])
		rows = result.rows |> Enum.filter(fn(r) ->
			data = Enum.at(r, 1)
			data != nil
		end)
		votes = for row <- rows, into: %{}, do: {Enum.at(row, 0), Enum.at(row, 1)["score_by_choices"]}
		votes
	end
end

# t(result) = #delegations
# t(select) + #votes * t(result)
# 1 way is to have time graph only with default trust metric from cache
# calculate result at N times, N * (t(select) + t(result))
# another way is to send needed data to client (all relevant users and delegations and votes). 1M delegations * (4B, 3B, 3B, 1B) + 100K votes * (4B, 3B, 1B * # choices) = 1M * 11B + 100K * 10B = 12MB