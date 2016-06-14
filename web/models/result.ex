defmodule Democracy.VotingPowerServer do
	def start_link do
		Agent.start_link(fn -> Map.new end, name: __MODULE__)
	end

	def get(identity_id) do
		Agent.get(__MODULE__, fn map ->
			Map.get(map, identity_id)
		end)
	end

	def put(identity_id, power) do
		Agent.update(__MODULE__, &Map.put(&1, identity_id, power))
	end
end

defmodule Democracy.TotalDelegationsWeightServer do
	def start_link do
		Agent.start_link(fn -> {Map.new, MapSet.new} end, name: __MODULE__)
	end

	def get(identity_id) do
		Agent.get(__MODULE__, fn({weights, done_ids}) ->
			Map.get(weights, identity_id)
		end)
	end

	def add(identity_id, weight) do
		Agent.update(__MODULE__, fn({weights, done_ids}) ->
			new_total = Map.get(weights, identity_id, 0) + weight
			{Map.put(weights, identity_id, new_total), done_ids}
		end)
	end

	def is_done?(identity_id) do
		Agent.get(__MODULE__, fn({weights, done_ids}) ->
			MapSet.member?(done_ids, identity_id)
		end)
	end

	def add_done(identity_id) do
		Agent.update(__MODULE__, fn({weights, done_ids}) ->
			{weights, MapSet.put(done_ids, identity_id)}
		end)
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
		unless poll.is_direct do
			inverse_delegations = get_inverse_delegations(datetime)
			topics = if poll.topics == nil do nil else poll.topics |> MapSet.new end
			calculate_contributions(votes, inverse_delegations, trust_identity_ids, poll.topics, poll.choices)
		else
			calculate_direct_contributions(votes, trust_identity_ids, poll.choices)
		end
	end

	def calculate_contributions(votes, inverse_delegations, trust_identity_ids, topics, choices) do
		Democracy.VotingPowerServer.start_link
		Democracy.TotalDelegationsWeightServer.start_link

		Enum.each(votes, fn({identity_id, data}) ->
			if MapSet.member?(trust_identity_ids, identity_id) do
				calculate_total_weights(identity_id, inverse_delegations, votes, topics, trust_identity_ids)
			end
		end)

		contributions = Enum.map(votes, fn({identity_id, data}) ->
			if MapSet.member?(trust_identity_ids, identity_id) do
				voting_power = get_power(identity_id, inverse_delegations, votes, topics, trust_identity_ids)
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

		data = for choice <- choices, into: %{}, do: {
			choice,
			calculate_contributions_for_choice(choice, Map.get(contributions_by_choice, choice, []))
		}
		
		data
	end

	def calculate_direct_contributions(votes, trust_identity_ids, choices) do
		contributions = Enum.map(votes, fn({identity_id, data}) ->
			if MapSet.member?(trust_identity_ids, identity_id) do
				Enum.map(data, fn({choice, score}) ->
					%{
						choice: choice,
						identity_id: identity_id,
						voting_power: 1,
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

	def calculate_total_weights(identity_id, inverse_delegations, votes, topics, trust_identity_ids) do
		unless Democracy.TotalDelegationsWeightServer.is_done?(identity_id) do
			inverse_delegations |> elem(identity_id - 1) |> Enum.each(fn({from_identity_id, from_weight, from_topics}) ->
				cond do
					not MapSet.member?(trust_identity_ids, from_identity_id) -> nil
					Map.has_key?(votes, from_identity_id) -> nil
					topics != nil and from_topics != nil and MapSet.disjoint?(topics, from_topics) -> nil
					true ->
						Democracy.TotalDelegationsWeightServer.add(from_identity_id, from_weight)
						calculate_total_weights(from_identity_id, inverse_delegations, votes, topics, trust_identity_ids)
				end
			end)
			Democracy.TotalDelegationsWeightServer.add_done(identity_id)
		end
	end

	def get_power(identity_id, inverse_delegations, votes, topics, trust_identity_ids) do
		power = Democracy.VotingPowerServer.get(identity_id)
		if power do
			power
		else
			receiving = inverse_delegations |> elem(identity_id - 1) |> Enum.reduce(0, fn({from_identity_id, from_weight, from_topics}, acc) ->
				acc + cond do
					not MapSet.member?(trust_identity_ids, from_identity_id) -> 0
					Map.has_key?(votes, from_identity_id) -> 0
					topics != nil and from_topics != nil and MapSet.disjoint?(topics, from_topics) -> 0
					true ->
						from_power = get_power(from_identity_id, inverse_delegations, votes, topics, trust_identity_ids)
						from_power * (from_weight / Democracy.TotalDelegationsWeightServer.get(from_identity_id))
				end
			end)
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

	def calculate_random(filename) do
		{trust_identity_ids, votes, inverse_delegations} = :erlang.binary_to_term(File.read! filename)

		calculate_contributions(votes, inverse_delegations, trust_identity_ids |> MapSet.new, nil, ["true"])
	end

	def create_random(filename, num_identities, num_votes, num_delegations_per_identity) do
		trust_identity_ids = Enum.to_list 1..num_identities
		votes = get_random_votes trust_identity_ids, num_votes
		inverse_delegations = get_random_inverse_delegations trust_identity_ids, num_delegations_per_identity

		{:ok, file} = File.open filename, [:write]
		IO.binwrite file, :erlang.term_to_binary({trust_identity_ids, votes, inverse_delegations})
	end

	def get_random_inverse_delegations(identity_ids, num_delegations) do
		r = for to_identity_id <- identity_ids, do: identity_ids
			|> Enum.slice(max(0, to_identity_id - num_delegations - 1), min(to_identity_id - 1, num_delegations))
			|> Enum.map(& {&1, 1, nil})
		r |> List.to_tuple
	end

	def get_random_votes(identity_ids, num_votes) do
		for identity_id <- identity_ids |> Enum.take_random(num_votes), into: %{}, do: {
			identity_id,
			%{"true" => :random.uniform}
		}
	end
end