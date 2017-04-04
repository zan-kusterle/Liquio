defmodule Liquio.CalculateResults do
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Identity, Repo, GetData, Results, CalculateMemoServer}


	def calculate_for_votes(votes, calculation_opts) do
		votes = for vote <- votes, into: %{} do
			{vote.identity_id, vote}
		end
		inverse_delegations = GetData.get_inverse_delegations(calculation_opts.datetime)
		contributions = calculate(votes, inverse_delegations, calculation_opts.trust_metric_ids, [])
		|> Repo.preload([:identity])

		Results.from_contributions(contributions, calculation_opts)
	end

	def calculate(votes, inverse_delegations, trust_identity_ids, topics) do
		topics = if is_list(topics) do MapSet.new(topics) else topics end

		uuid = String.to_atom(UUID.uuid4(:hex))

		CalculateMemoServer.start_link uuid

		state = {inverse_delegations, votes, topics, trust_identity_ids}

		trust_votes = votes |> Enum.filter(fn({identity_id, _vote}) ->
			MapSet.member?(trust_identity_ids, to_string(identity_id))
		end)

		Enum.each(trust_votes, fn({identity_id, _vote}) ->
			calculate_total_weights(identity_id, state, uuid, MapSet.new)
		end)
		
		CalculateMemoServer.reset_visited(uuid)

		contributions = trust_votes |> Enum.map(fn({identity_id, vote}) ->
			vote
			|> Map.put(:voting_power, get_power(identity_id, state, uuid, MapSet.new) / 1)
		end)

		CalculateMemoServer.stop uuid

		total_voting_power = contributions |> Enum.map(& &1.voting_power) |> Enum.sum
		contributions = contributions |> Enum.map(fn(contribution) ->
			contribution
			|> Map.put(:weight, contribution.voting_power / total_voting_power)
		end)
		
		contributions
	end

	defp calculate_total_weights(identity_id, state = {inverse_delegations, _votes, _topics, _trust_identity_ids}, uuid, path) do
		unless CalculateMemoServer.visited?(uuid, identity_id) do
			inverse_delegations |> Map.get(identity_id, [])
			|> Enum.filter(& use_delegation?(&1, state, path))
			|> Enum.each(fn({from_identity_id, from_weight, _from_topics}) ->
				CalculateMemoServer.add_weight(uuid, from_identity_id, from_weight)
				calculate_total_weights(from_identity_id, state, uuid, MapSet.put(path, identity_id))
			end)
			CalculateMemoServer.add_visited(uuid, identity_id)
		end
	end

	defp get_power(identity_id, state = {inverse_delegations, _votes, _topics, _trust_identity_ids}, uuid, path) do
		if power = CalculateMemoServer.get_power(uuid, identity_id) do
			power
		else
			receiving = inverse_delegations |> Map.get(identity_id, [])
			|> Enum.filter(& use_delegation?(&1, state, path))
			|> Enum.reduce(0, fn({from_identity_id, from_weight, _from_topics}, acc) ->
				from_power = get_power(from_identity_id, state, uuid, MapSet.put(path, identity_id))
				from_ratio = from_weight / CalculateMemoServer.get_total_weight(uuid, from_identity_id)
				acc + from_power * from_ratio
			end)
			power = 1 + receiving
			CalculateMemoServer.put_power(uuid, identity_id, power)
			power
		end
	end

	defp use_delegation?({from_identity_id, _from_weight, from_topics}, {_inverse_delegations, votes, topics, trust_identity_ids}, path) do
		MapSet.member?(trust_identity_ids, to_string(from_identity_id)) and
		not Map.has_key?(votes, from_identity_id) and
		(topics == nil or from_topics == nil or not MapSet.disjoint?(topics, from_topics)) and
		not MapSet.member?(path, from_identity_id)
	end
end

defmodule Liquio.CalculateMemoServer do
	def start_link(uuid) do
		Agent.start_link(fn -> {Map.new, Map.new, MapSet.new} end, name: uuid)
	end

	def stop(uuid) do
		Agent.stop(uuid)
	end

	def get_power(uuid, identity_id) do
		Agent.get(uuid, fn({powers, _weights, _done_ids}) ->
			Map.get(powers, identity_id)
		end)
	end

	def put_power(uuid, identity_id, power) do
		Agent.update(uuid, fn({powers, weights, done_ids}) ->
			{Map.put(powers, identity_id, power), weights, done_ids}
		end)
	end

	def get_total_weight(uuid, identity_id) do
		Agent.get(uuid, fn({_powers, weights, _done_ids}) ->
			Map.get(weights, identity_id)
		end)
	end

	def add_weight(uuid, identity_id, weight) do
		Agent.update(uuid, fn({powers, weights, done_ids}) ->
			new_total = Map.get(weights, identity_id, 0) + weight
			{powers, Map.put(weights, identity_id, new_total), done_ids}
		end)
	end

	def visited?(uuid, identity_id) do
		Agent.get(uuid, fn({_powers, _weights, done_ids}) ->
			MapSet.member?(done_ids, identity_id)
		end)
	end

	def add_visited(uuid, identity_id) do
		Agent.update(uuid, fn({powers, weights, done_ids}) ->
			{powers, weights, MapSet.put(done_ids, identity_id)}
		end)
	end

	def reset_visited(uuid) do
		Agent.update(uuid, fn({powers, weights, _done_ids}) ->
			{powers, weights, MapSet.new}
		end)
	end
end