defmodule Liquio.ReferenceRepo do
	alias Liquio.Repo
	
	def load(node, calculation_opts) do
		load(node, calculation_opts, nil)
	end
	def load(node, calculation_opts, user) do
		key = {
			{"nodes", node.group_key, calculation_opts.datetime},
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
			node = load_latest(node, calculation_opts, user)
			ResultsCache.set(key, node)
			node
		end
	end

	def invalidate_cache(node) do
		ResultsCache.unset({"nodes", {Enum.join(node.path, "/"), Enum.join(node.reference_path, "/")}})
		ResultsCache.unset({"nodes", {Enum.join(node.path, "/"), nil}})
		ResultsCache.unset({"nodes", {Enum.join(node.reference_path, "/"), nil}})
	end

	def load_latest(node, calculation_opts, user) do
		node = node
		|> Map.put(:calculation_opts, calculation_opts)
		|> Reference.load_references(calculation_opts)
		|> Reference.load_inverse_references(calculation_opts)
		|> load_results(calculation_opts)
		|> load_own_contribution(user)

		node = if calculation_opts.depth == 0 do
			node |> Map.drop([:inverse_references, :topics])
		else
			node
		end

		node
	end
	
	def load_own_contribution(node, user) do
		vote = if Map.has_key?(node, :own_vote) do
			node.own_vote
		else
			if user do Vote.current_by(node, user) else nil end
		end

		contribution = if vote do
			contribution = if Map.has_key?(node, :results) and user != nil do
				Enum.find(node.results.contributions, & &1.identity.username == user.username)
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
	
	def load_results(reference, calculation_opts) do
		votes = ReferenceVote.get_votes(reference.path, reference.reference_path, calculation_opts.datetime)
		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)
		contributions = CalculateResults.calculate(votes, inverse_delegations, calculation_opts.trust_metric_ids, node.topics) |> Repo.preload([:identity])
		results = Results.from_contributions(contributions, calculation_opts)

		node
		|> Map.put(:results, results)
	end

	def load_references(node, calculation_opts, current_depth \\ nil) do
		depth = if current_depth == nil do calculation_opts.depth else current_depth end
		if depth > 0 do
			reference_nodes = from(v in ReferenceVote, where: v.group_key == ^node.group_key and v.is_last == true and not is_nil(v.relevance))
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

	def load_inverse_references(node, calculation_opts, current_depth \\ nil) do
		depth = if current_depth == nil do calculation_opts.depth else current_depth end
		if depth > 0 do
			inverse_reference_nodes = from(v in Vote, where: v.reference_path == ^node.path and v.is_last == true and not is_nil(v.choice))
			|> Repo.all
			|> Enum.group_by(& &1.key)
			|> prepare_reference_nodes(calculation_opts)

			inverse_reference_nodes = if depth > 1 do
				inverse_reference_nodes |> Enum.map(fn(inverse_reference_node) ->
					inverse_reference_node |> load_inverse_references(calculation_opts, depth: depth - 1) |> load_references(calculation_opts, 1)
				end)
			else
				inverse_reference_nodes
			end

			topics = inverse_reference_nodes
			|> Enum.filter(& Enum.count(&1.path) == 1 and String.length(Enum.at(&1.path, 0)) <= 20)
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
			results = votes
			|> Enum.filter(& &1.filter_key == "relevance")
			|> CalculateResults.calculate_for_votes(calculation_opts)
			{key, results}
		end)
		|> Enum.filter(fn({_key, result}) ->
			result.total > 0 and result.turnout_ratio >= calculation_opts[:reference_minimum_turnout]
		end)
		|> Enum.map(fn({key, result}) ->
			Node.decode(key)
			|> load_results(calculation_opts)
			|> Map.put(:reference_result, result)
		end)
		|> Enum.sort_by(& -&1.reference_result.mean)
	end
end