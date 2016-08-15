defmodule Liquio.CalculateResultServer do
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

defmodule Liquio.Result do
	use Liquio.Web, :model

	alias Liquio.Repo

	schema "results" do
		belongs_to :poll, Liquio.Poll
		field :trust_metric_key, :string
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :data, :map
	end

	def calculate(poll, calculate_opts = %{:datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :soft_quorum_t => soft_quorum_t}) do
		datetime = if datetime == nil do Timex.DateTime.now else datetime end
		soft_quorum_t = if poll.kind == "custom" do 0 else soft_quorum_t end
		mean_fn = if poll.choice_type == "quantity" do &median/2 else &mean/2 end
		
		poll
		|> calculate_contributions(calculate_opts)
		|> aggregate_contributions(datetime, vote_weight_halving_days, soft_quorum_t, mean_fn)
	end

	def empty() do
		%{
			:mean => nil,
			:total => 0,
			:count => 0
		}
	end

	def calculate_contributions(poll, %{:datetime => datetime, :trust_metric_ids => trust_metric_ids}) do
		datetime = if datetime == nil do Timex.DateTime.now else datetime end
		trust_metric_ids = if trust_metric_ids == nil do MapSet.new else trust_metric_ids end
		topics = if poll.topics == nil do nil else poll.topics |> MapSet.new end

		votes = get_votes(poll.id, datetime)
		inverse_delegations = get_inverse_delegations(datetime)

		calculate_contributions_for_data(votes, inverse_delegations, trust_metric_ids, topics)
	end

	def calculate_contributions_for_data(votes, inverse_delegations, trust_identity_ids, topics) do
		uuid = UUID.uuid4(:hex) |> String.to_atom

		Liquio.CalculateResultServer.start_link uuid

		state = {inverse_delegations, votes, topics, trust_identity_ids}

		trust_votes = votes |> Enum.filter(fn({identity_id, {_datetime, _score}}) ->
			MapSet.member?(trust_identity_ids, to_string(identity_id))
		end)

		Enum.each(trust_votes, fn({identity_id, {_datetime, _score}}) ->
			calculate_total_weights(identity_id, state, uuid)
		end)

		Liquio.CalculateResultServer.reset_visited(uuid)

		contributions = trust_votes |> Enum.map(fn({identity_id, {datetime, score}}) ->
			%{
				identity_id: identity_id,
				voting_power: get_power(identity_id, state, uuid) / 1,
				score: score,
				datetime: datetime
			}
		end)

		Liquio.CalculateResultServer.stop uuid

		contributions
	end

	def aggregate_contributions(contributions, datetime, vote_weight_halving_days, soft_quorum_t, mean_fn) do
		contributions = contributions |> Enum.map(fn(contribution) ->
			contribution
			|> Map.put(:voting_power, contribution.voting_power * moving_average_weight(contribution, datetime, vote_weight_halving_days))
		end)
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))

		%{
			:mean => mean_fn.(contributions, soft_quorum_t),
			:total => round(total_power),
			:count => Enum.count(contributions)
		}
	end

	def mean(contributions, soft_quorum_t) do
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))
		total_score = Enum.sum(Enum.map(contributions, & &1.score * &1.voting_power))
		if total_power + soft_quorum_t > 0 do
			total_score / (total_power + soft_quorum_t)
		else
			nil
		end
	end

	def median(contributions, _soft_quorum_t) do
		contributions = contributions |> Enum.sort(&(&1.score > &2.score))
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))
		if total_power > 0 do
			Enum.reduce_while(contributions, 0.0, fn(contribution, current_power) ->
				if current_power + contribution.voting_power > total_power / 2 do
					{ :halt, contribution.score }
				else
					{ :cont, current_power + contribution.voting_power }
				end
			end)
		else
			nil
		end
	end

	def moving_average_weight(contribution, reference_datetime, vote_weight_halving_days) do
		if vote_weight_halving_days == nil do
			1
		else
			ct = contribution.datetime |> Timex.to_erlang_datetime |> :calendar.datetime_to_gregorian_seconds
			rt = reference_datetime |> Timex.to_erlang_datetime |> :calendar.datetime_to_gregorian_seconds
			delta_days = (rt - ct) / (24 * 3600)

			base = :math.pow(0.5, 1 / vote_weight_halving_days)
			:math.pow(base, delta_days)
		end
	end

	def calculate_total_weights(identity_id, state, uuid) do
		{inverse_delegations, votes, topics, trust_identity_ids} = state

		unless Liquio.CalculateResultServer.visited?(uuid, identity_id) do
			inverse_delegations |> Map.get(identity_id, []) |> Enum.each(fn({from_identity_id, from_weight, from_topics}) ->
				cond do
					not MapSet.member?(trust_identity_ids, to_string(from_identity_id)) -> nil
					Map.has_key?(votes, from_identity_id) -> nil
					topics != nil and from_topics != nil and MapSet.disjoint?(topics, from_topics) -> nil
					true ->
						Liquio.CalculateResultServer.add_weight(uuid, from_identity_id, from_weight)
						calculate_total_weights(from_identity_id, state, uuid)
				end
			end)
			Liquio.CalculateResultServer.add_visited(uuid, identity_id)
		end
	end

	def get_power(identity_id, state, uuid) do
		{inverse_delegations, votes, topics, trust_identity_ids} = state

		power = Liquio.CalculateResultServer.get_power(uuid, identity_id)
		if power do
			power
		else
			Liquio.CalculateResultServer.add_visited(uuid, identity_id)
			receiving = inverse_delegations |> Map.get(identity_id, []) |> Enum.reduce(0, fn({from_identity_id, from_weight, from_topics}, acc) ->
				acc + cond do
					not MapSet.member?(trust_identity_ids, to_string(from_identity_id)) -> 0
					Map.has_key?(votes, from_identity_id) -> 0
					topics != nil and from_topics != nil and MapSet.disjoint?(topics, from_topics) -> 0
					true ->
						from_power = get_power(from_identity_id, state, uuid)
						from_power * (from_weight / Liquio.CalculateResultServer.get_total_weight(uuid, from_identity_id))
				end
			end)
			power = 1 + receiving
			Liquio.CalculateResultServer.put_power(uuid, identity_id, power)
			power
		end
	end

	def get_inverse_delegations(datetime) do
		query = "SELECT DISTINCT ON (from_identity_id, to_identity_id) from_identity_id, to_identity_id, data
			FROM delegations
			WHERE datetime <= '#{Timex.format!(datetime, "{ISO}")}'
			ORDER BY from_identity_id, to_identity_id, datetime DESC;"
		rows = Ecto.Adapters.SQL.query!(Repo, query , []).rows |> Enum.filter(& Enum.at(&1, 2))
		inverse_delegations = for {to_identity_id, to_identity_rows} <- rows |> Enum.group_by(&(&1 |> Enum.at(1))), into: %{}, do: {
			to_identity_id,
			to_identity_rows |> Enum.map(fn(row) ->
				{
					Enum.at(row, 0),
					Enum.at(row, 2)["weight"],
					if Enum.at(row, 2)["topics"] == nil do nil else Enum.at(row, 2)["topics"] |> MapSet.new end
				}
			end)
		}
		inverse_delegations
	end

	def get_votes(poll_id, datetime) do
		query = "SELECT DISTINCT ON (v.identity_id) v.identity_id, v.datetime, v.data
			FROM votes AS v
			WHERE v.poll_id = #{poll_id} AND v.datetime <= '#{Timex.format!(datetime, "{ISO}")}'
			ORDER BY v.identity_id, v.datetime DESC;"
		rows = Ecto.Adapters.SQL.query!(Repo, query , []).rows |> Enum.filter(& Enum.at(&1, 2))
		votes = for row <- rows, into: %{} do
			{date, {h, m, s, _}} = Enum.at(row, 1)
			data = {
				Timex.datetime({date, {h, m, s}}),
				Enum.at(row, 2)["score"]
			}
			{Enum.at(row, 0), data}
		end
		votes
	end

	def calculate_random(filename) do
		{trust_identity_ids, votes, inverse_delegations} = :erlang.binary_to_term(File.read! filename)

		calculate_contributions_for_data(votes, inverse_delegations, trust_identity_ids, nil)
	end

	def create_random(filename, num_identities, num_votes, num_delegations_per_identity) do
		trust_identity_ids = Enum.to_list 1..num_identities
		votes = get_random_votes trust_identity_ids, num_votes
		inverse_delegations = get_random_inverse_delegations trust_identity_ids, num_delegations_per_identity

		{:ok, file} = File.open filename, [:write]
		IO.binwrite file, :erlang.term_to_binary({trust_identity_ids |> MapSet.new, votes, inverse_delegations})
	end

	def get_random_inverse_delegations(identity_ids, num_delegations) do
		for to_identity_id <- identity_ids, into: %{}, do: {to_identity_id,
			identity_ids
			|> Enum.slice(max(0, to_identity_id - num_delegations - 1), min(to_identity_id - 1, num_delegations))
			|> Enum.map(& {&1, 1, nil})
		}
	end

	def get_random_votes(identity_ids, num_votes) do
		for identity_id <- identity_ids |> Enum.take_random(num_votes), into: %{}, do: {
			identity_id,
			{
				Timex.DateTime.now,
				:random.uniform
			}
		}
	end
end