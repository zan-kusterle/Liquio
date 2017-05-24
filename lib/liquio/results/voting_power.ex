defmodule Liquio.VotingPower do
	alias Liquio.CalculateMemoServer

	def get(usernames, inverse_delegations) do
		get(usernames, inverse_delegations, :timer.seconds(Application.get_env(:liquio, :results_cache_seconds)))
	end
	def get(usernames, inverse_delegations, cache_time) do
		key = {usernames, inverse_delegations}

		power = Cachex.get!(:voting_power, key)
		power = if power do
			power
		else
			data = calculate(usernames, inverse_delegations)
			Cachex.set(:voting_power, key, data, ttl: cache_time)
			data
		end

		power
	end

	def calculate(usernames, inverse_delegations) do
		uuid = String.to_atom(UUID.uuid4(:hex))

		CalculateMemoServer.start_link uuid

		Enum.each(usernames, fn(username) ->
			calculate_total_weights(username, inverse_delegations, uuid, MapSet.new)
		end)

		CalculateMemoServer.reset_visited(uuid)

		power_by_usernames = usernames |> Enum.map(fn(username) ->
			{username, get_power(username, inverse_delegations, uuid, MapSet.new) / 1}
		end) |> Enum.into(%{})

		CalculateMemoServer.stop uuid

		power_by_usernames
	end

	defp calculate_total_weights(identity_id, inverse_delegations, uuid, path) do
		unless CalculateMemoServer.visited?(uuid, identity_id) do
			inverse_delegations |> Map.get(identity_id, [])
			|> Enum.each(fn({from_identity_id, from_weight, _from_topics}) ->
				CalculateMemoServer.add_weight(uuid, from_identity_id, from_weight)
				calculate_total_weights(from_identity_id, inverse_delegations, uuid, MapSet.put(path, identity_id))
			end)
			CalculateMemoServer.add_visited(uuid, identity_id)
		end
	end

	defp get_power(identity_id, inverse_delegations, uuid, path) do
		if power = CalculateMemoServer.get_power(uuid, identity_id) do
			power
		else
			receiving = inverse_delegations |> Map.get(identity_id, [])
			|> Enum.reduce(0, fn({from_identity_id, from_weight, _from_topics}, acc) ->
				from_power = get_power(from_identity_id, inverse_delegations, uuid, MapSet.put(path, identity_id))
				from_ratio = from_weight / CalculateMemoServer.get_total_weight(uuid, from_identity_id)
				acc + from_power * from_ratio
			end)
			power = 1 + receiving
			CalculateMemoServer.put_power(uuid, identity_id, power)
			power
		end
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