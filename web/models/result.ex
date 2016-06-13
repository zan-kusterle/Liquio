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
		inverse_delegations = if poll.is_direct do nil else get_delegations(poll, trust_metric_key, datetime) end
		votes = get_votes(poll, trust_metric_key, datetime)

		IO.inspect inverse_delegations
		IO.inspect votes

		:ets.new(:power_registry, [:named_table])
		contributions = Enum.map(votes, fn({identity_id, data}) ->
			voting_power = if poll.is_direct do
				1
			else
				get_power(identity_id, inverse_delegations, votes)
			end
			Enum.map(data, fn({choice, score}) ->
				%{
					choice: choice,
					identity_id: identity_id,
					voting_power: voting_power,
					score: score
				}
			end)
		end) |> List.flatten

		contributions_by_choice = contributions |> Enum.group_by(&(&1.choice))

		for choice <- poll.choices, into: %{}, do: {
			choice,
			calculate_for_choice(choice, Map.get(contributions_by_choice, choice, []))
		}
	end

	def calculate_for_choice(choice, contributions_for_choice) do
		contributions_by_identities = for contribution <- contributions_for_choice, into: %{}, do: {to_string(contribution.identity_id), %{
			:voting_power => contribution.voting_power,
			:score => contribution.score
		}}
		total_power = Enum.sum(Enum.map(contributions_for_choice, & &1.voting_power))
		total_score = Enum.sum(Enum.map(contributions_for_choice, & &1.score * &1.voting_power))
		mean = total_score / total_power
		
		%{
			:mean => mean,
			:total => total_power,
			:contributions_by_identities => contributions_by_identities
		}
	end

	def get_power(identity_id, inverse_delegations, votes) do
		power = case :ets.lookup(:power_registry, identity_id) do
			[{^identity_id, bucket}] -> bucket
			[] -> nil
		end
		if power do
			power
		else
			receiving = inverse_delegations |> Map.get(identity_id, %{}) |> Enum.map(fn({from_identity_id, from_ratio}) ->
				if Map.has_key?(votes, from_identity_id) do
					0
				else
					from_power = get_power(from_identity_id, inverse_delegations, votes)
					from_power * from_ratio
				end
			end) |> Enum.sum
			power = 1 + receiving
			:ets.insert(:power_registry, {identity_id, power})
			power
		end
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
		total_weight_by_identity_id = for {from_identity_id, from_identity_rows} <- rows |> Enum.group_by(&(&1 |> Enum.at(0))), into: %{}, do: {
			from_identity_id,
			from_identity_rows |> Enum.map(&(Enum.at(&1, 2)["weight"])) |> Enum.sum
		}
		inverse_delegations = for {to_identity_id, to_identity_rows} <- rows |> Enum.group_by(&(&1 |> Enum.at(1))), into: %{}, do: {
			to_identity_id,
			(for row <- to_identity_rows, into: %{}, do: {Enum.at(row, 0), Enum.at(row, 2)["weight"] / total_weight_by_identity_id[Enum.at(row, 0)]})
		}
		inverse_delegations
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