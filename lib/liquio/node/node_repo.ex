defmodule Liquio.NodeRepo do
	import Ecto
	import Ecto.Query, only: [from: 1, from: 2]
	alias Liquio.{Node, Identity, Vote, ResultsCache, Repo}
	alias Liquio.Results

	def all(calculation_opts) do
		key = {
			{"nodes", {"all", nil}, calculation_opts.datetime},
			{
				calculation_opts.trust_metric_url,
				calculation_opts.minimum_voting_power,
				calculation_opts.reference_minimum_turnout
			}
		}
		cache_results = ResultsCache.get(key)
		if cache_results do
			cache_results
		else
			nodes = Vote
			|> Repo.all
			|> Enum.map(& &1.key)
			|> Enum.uniq
			|> Enum.map(& Node.decode(&1) |> load(calculation_opts, nil))
			|> Enum.sort_by(& -(&1.results.turnout_ratio + 0.05 * Enum.count(&1.references)))
			|> Enum.map(& Map.drop(&1, [:references, :inverse_references]))

			node = Node.decode("") |> Map.put(:references, nodes) |> Map.put(:calculation_opts, calculation_opts)

			ResultsCache.set(key, node)
			node
		end
	end

	def search(query, calculation_opts) do
		nodes = Vote
		|> Vote.search(query)
		|> Repo.all
		|> Enum.map(& &1.key)
		|> Enum.uniq
		|> Enum.map(& Node.decode(&1) |> load(calculation_opts |> Map.put(:depth, 0), nil))

		Node.decode("Results for #{query}" |> String.replace(" ", "-"))
		|> Map.put(:references, nodes) |> Map.put(:calculation_opts, calculation_opts)
	end

	def load(node, calculation_opts) do
		load(node, calculation_opts, nil)
	end
	def load(node, calculation_opts, user) do
		key = {
			{"nodes", {node.key, node.reference_key}, calculation_opts.datetime},
			{
				calculation_opts.trust_metric_url,
				calculation_opts.minimum_voting_power,
				calculation_opts.reference_minimum_turnout,
				calculation_opts.depth
			}
		}
		cache_results = ResultsCache.get(key)
		if cache_results do
			cache_results
		else
			node = node |> load_without_cache(calculation_opts, user)
			ResultsCache.set(key, node)
			node
		end
	end

	def load_unit(node) do
		units = Application.get_env(:liquio, :units)
		unit = if Map.has_key?(units, node.choice_type) do units[node.choice_type] else nil end
		{unit_type, unit_a, unit_b} = if unit do unit else {:probability, to_string(node.choice_type), nil} end

		node
		|> Map.put(:unit_type, unit_type)
		|> Map.put(:unit_a, unit_a)
		|> Map.put(:unit_b, unit_b)
	end
	
	def load_own_contribution(node, user) do
		vote = if Map.has_key?(node, :own_vote) do
			node.own_vote
		else
			if user do Vote.current_by(node, user) else nil end
		end

		contribution = if vote do
			contribution = if Map.has_key?(node, :contributions) and user != nil do
				Enum.find(node.contributions, & &1.identity.id == user.id)
			else
				nil
			end

			contribution = if contribution do
				contribution
			else
				vote
				|> Map.put(:voting_power, 0.0)
				|> Map.put(:identity, user)
			end
			
			results = Results.from_contribution(contribution)
			contribution
			|> Map.put(:results, results)
		else
			nil
		end

		node
		|> Map.put(:own_vote, vote)
		|> Map.put(:own_contribution, contribution)
	end

	defp load_without_cache(node, calculation_opts, user) do
		node = node
		|> Map.put(:calculation_opts, calculation_opts)
		|> load_unit
		|> load_references(calculation_opts)
		|> load_inverse_references(calculation_opts)
		|> load_results(calculation_opts)
		|> load_own_contribution(user)

		if calculation_opts.depth == 0 do
			node |> Map.drop([:inverse_references, :topics])
		else
			node
		end
	end

	defp load_results(node, calculation_opts) do
		node = if not Map.has_key?(node, :contributions) do
			node |> load_contributions(calculation_opts)
		else
			node
		end

		results = Results.from_contributions(node.contributions, calculation_opts)
		node = Map.put(node, :results, results)

		node
	end

	defp load_contributions(node, calculation_opts) do
		node = if not Map.has_key?(node, :topics) do
			node |> load_inverse_references(calculation_opts, 1)
		else
			node
		end

		results = Contribution.calculate(node, calculation_opts)

		node = if not Enum.empty?(results.contributions) do
			{best_title, _count} = results.contributions
			|> Enum.map(& &1.title)
			|> Enum.group_by(& &1.title)
			|> Enum.map(fn({k, v}) -> {k, Enum.count(v)} end)
			|> Enum.max_by(fn({title, count}) -> count end)

			node |> Node.put_title(best_title)
		else
			node
		end

		Map.put(node, :contributions, contributions)
	end

	defp load_references(node, calculation_opts, current_depth \\ nil) do
		depth = if current_depth == nil do calculation_opts.depth else current_depth end
		if depth > 0 do
			reference_nodes = from(v in Vote, where: v.group_key == ^node.key and not is_nil(v.reference_key) and v.is_last == true and not is_nil(v.data))
			|> Repo.all
			|> Enum.group_by(& &1.reference_key)
			|> prepare_reference_nodes(calculation_opts)

			reference_nodes = if depth > 1 do
				reference_nodes |> Enum.map(fn(reference_node) ->
					reference_node |> load_references(calculation_opts, depth - 1) |> load_inverse_references(calculation_opts, 1)
				end)
			else
				reference_nodes
			end

			Map.put(node, :references, reference_nodes)
		else
			node
		end
	end

	defp load_inverse_references(node, calculation_opts, current_depth \\ nil) do
		depth = if current_depth == nil do calculation_opts.depth else current_depth end
		if depth > 0 do
			inverse_reference_nodes = from(v in Vote, where: v.reference_title == ^String.downcase(node.title) and v.is_last == true and not is_nil(v.data))
			|> Repo.all
			|> Enum.group_by(& &1.key)
			|> prepare_reference_nodes(calculation_opts)

			inverse_reference_nodes = if depth > 1 do
				inverse_reference_nodes |> Enum.map(fn(inverse_reference_node) ->
					inverse_reference_node |> load_inverse_references(calculation_opts, depth: depth - 1)
				end)
			else
				inverse_reference_nodes
			end

			topics = inverse_reference_nodes
			|> Enum.filter(& &1.choice_type == nil)
			|> Enum.map(& &1.key)

			node = Map.put(node, :inverse_references, inverse_reference_nodes)
			node = Map.put(node, :topics, topics)

			node
		else
			node
		end
	end

	defp prepare_reference_nodes(keys_with_votes, calculation_opts) do
		keys_with_votes
		|> Enum.map(fn({key, votes}) ->
			{key, Contribution.calculate_for_votes(votes, calculation_opts)}
		end)
		|> Enum.filter(fn({_key, result}) ->
			Map.has_key?(result.by_keys, "relevance") and result.total > 0 and result.turnout_ratio >= calculation_opts[:reference_minimum_turnout]
		end)
		|> Enum.map(fn({key, result}) ->
			Node.decode(key)
			|> load_results(calculation_opts)
			|> Map.put(:reference_result, result)
		end)
		|> Enum.sort_by(& -&1.reference_result.by_keys["relevance"].mean)
	end
end