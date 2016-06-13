defmodule Democracy.VotingPowerServer do
	def start_link do
		Agent.start_link(fn -> HashDict.new end, name: __MODULE__)
	end

	def get(identity_id) do
		Agent.get(__MODULE__, fn dict ->
			Dict.get(dict, identity_id)
		end)
	end

	def put(identity_id, power) do
		Agent.update(__MODULE__, &Dict.put(&1, identity_id, power))
	end
end

defmodule Democracy.Result do
	use Democracy.Web, :model

	alias Democracy.Repo

	schema "results" do
		belongs_to :poll, Democracy.Poll
		field :trust_metric_key, :string
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :data, :map
	end

	def calculate(poll, datetime, trust_identity_ids) do
		votes = get_votes(poll.id, datetime)
		inverse_delegations = if poll.is_direct do nil else get_inverse_delegations(datetime) end
		topics = if poll.topics == nil do nil else poll.topics |> MapSet.new end

		calculate_contributions(votes, inverse_delegations, trust_identity_ids, poll.topics, poll.choices, poll.is_direct)
	end

	def calculate_contributions(votes, inverse_delegations, trust_identity_ids, topics, choices, is_direct \\ false) do
		Democracy.VotingPowerServer.start_link

		contributions = Enum.map(votes, fn({identity_id, data}) ->
			if MapSet.member?(trust_identity_ids, identity_id) do
				voting_power = if is_direct do 1 else get_power(identity_id, inverse_delegations, votes, topics, trust_identity_ids) end
				Enum.map(data, fn({choice, score}) ->
					%{
						choice: choice,
						identity_id: identity_id,
						voting_power: voting_power,
						score: score
					}
				end)
			else
				[]
			end
		end) |> List.flatten

		contributions_by_choice = contributions |> Enum.group_by(&(&1.choice))

		for choice <- choices, into: %{}, do: {
			choice,
			calculate_contributions_for_choice(choice, Map.get(contributions_by_choice, choice, []))
		}
	end

	def calculate_contributions_for_choice(choice, contributions_for_choice) do
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
			#:contributions_by_identities => contributions_by_identities
		}
	end

	def get_power(identity_id, inverse_delegations, votes, topics, trust_identity_ids) do
		power = Democracy.VotingPowerServer.get(identity_id)
		if power do
			power
		else
			receiving = inverse_delegations |> Map.get(identity_id, %{}) |> Enum.map(fn({from_identity_id, {from_ratio, from_topics}}) ->
				cond do
					not MapSet.member?(trust_identity_ids, identity_id) -> 0
					Map.has_key?(votes, from_identity_id) -> 0
					topics != nil and from_topics != nil and MapSet.disjoint?(topics, from_topics) -> 0
					true ->
						from_power = get_power(from_identity_id, inverse_delegations, votes, topics, trust_identity_ids)
						from_power * from_ratio
				end
			end) |> Enum.sum
			power = 1 + receiving
			Democracy.VotingPowerServer.put(identity_id, power)
			power
		end
	end

	def get_inverse_delegations(datetime) do
		query = "SELECT DISTINCT ON (from_identity_id, to_identity_id) from_identity_id, to_identity_id, data
			FROM delegations
			WHERE datetime <= '#{Ecto.DateTime.to_iso8601(datetime)}'
			ORDER BY from_identity_id, to_identity_id, datetime DESC;"
		result = Ecto.Adapters.SQL.query!(Repo, query , [])
		rows = result.rows |> Enum.filter(fn(r) ->
			data = Enum.at(r, 2)
			data != nil
		end)
		inverse_delegations = for {to_identity_id, to_identity_rows} <- rows |> Enum.group_by(&(&1 |> Enum.at(1))), into: %{}, do: {
			to_identity_id,
			(for row <- to_identity_rows, into: %{}, do: {
				Enum.at(row, 0),
				{
					Enum.at(row, 2)["weight"],
					if Enum.at(row, 2)["topics"] == nil do nil else Enum.at(row, 2)["topics"] |> MapSet.new end
				}
			})
		}
		inverse_delegations
	end

	def get_votes(poll_id, datetime) do
		query = "SELECT DISTINCT ON (v.identity_id) v.identity_id, v.data
			FROM votes AS v
			WHERE v.poll_id = #{poll_id} AND v.datetime <= '#{Ecto.DateTime.to_iso8601(datetime)}'
			ORDER BY v.identity_id, v.datetime DESC;"
		result = Ecto.Adapters.SQL.query!(Repo, query , [])
		rows = result.rows |> Enum.filter(fn(r) ->
			data = Enum.at(r, 1)
			data != nil
		end)
		votes = for row <- rows, into: %{}, do: {Enum.at(row, 0), Enum.at(row, 1)["score_by_choices"]}
		votes
	end

	def calculate_random(num_identities, num_votes, num_delegations_per_identity) do
		trust_identity_ids = Enum.to_list 1..num_identities
		votes = get_random_votes trust_identity_ids, num_votes
		inverse_delegations = get_random_inverse_delegations trust_identity_ids, num_delegations_per_identity
		
		calculate_contributions(votes, inverse_delegations, trust_identity_ids |> MapSet.new, nil, ["true"])
	end

	def get_random_inverse_delegations(identity_ids, num_delegations) do
		for to_identity_id <- identity_ids, into: %{}, do: {
			to_identity_id,
			(for from_identity_id <- identity_ids |> Enum.take(to_identity_id - 1) |> Enum.take_random(num_delegations), into: %{}, do: {
				from_identity_id, {1, nil}
			})
		}
	end

	def get_random_votes(identity_ids, num_votes) do
		for identity_id <- identity_ids |> Enum.take_random(num_votes), into: %{}, do: {
			identity_id,
			%{"true" => :random.uniform}
		}
	end
end