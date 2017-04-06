defmodule Liquio.NodeRepo do
	alias Liquio.{Node, Delegation, Vote, VoteRepo, ResultsCache, ReferenceRepo, ReferenceVote, Repo, Results}

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
			|> Enum.map(& &1.path)
			|> Enum.uniq
			|> Enum.map(& %Node{path: &1} |> load(calculation_opts, nil))
			|> Enum.sort_by(& -(&1.results["all"].probability.turnout_ratio + 0.05 * Enum.count(&1.references)))
			|> Enum.map(& Map.drop(&1, [:references, :inverse_references]))

			node = Node.decode("") |> Map.put(:references, nodes) |> Map.put(:calculation_opts, calculation_opts)

			ResultsCache.set(key, node)
			node
		end
	end

	def search(query, calculation_opts) do
		nodes = Vote
		|> VoteRepo.search(query)
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
			{"nodes", node.path, calculation_opts.datetime},
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
		ResultsCache.unset({"nodes", {Enum.join(node.path, "/"), nil}})
	end

	def load_latest(node, calculation_opts, user) do
		node = node
		|> Map.put(:calculation_opts, calculation_opts)
		|> load_references(calculation_opts)
		|> load_inverse_references(calculation_opts)
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
		votes = if Map.has_key?(node, :own_votes) do
			node.own_votes
		else
			if user do VoteRepo.current_by(user, node) else [] end
		end

		node
		|> Map.put(:own_votes, votes)
		|> Map.put(:own_results, Results.from_vote(Enum.at(votes, 0)))
	end

	def load_results(node, calculation_opts) do
		node = if not Map.has_key?(node, :topics) do
			node |> NodeRepo.load_inverse_references(calculation_opts, 1)
		else
			node
		end
		calculation_opts = calculation_opts |> Map.put(:topics, node.topics)

		votes = VoteRepo.get_at_datetime(node.path, calculation_opts.datetime) |> Repo.preload([:identity])

		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)
		results = votes |> Enum.group_by(& &1.unit) |> Enum.map(fn({unit, votes_for_unit}) ->
			{unit, Results.from_votes(votes_for_unit, inverse_delegations, calculation_opts)}
		end) |> Enum.into(%{})

		node = if not Enum.empty?(votes) do
			{best_title, _count} = votes
			|> Enum.map(& Enum.join(&1.path, "/"))
			|> Enum.group_by(& &1)
			|> Enum.map(fn({k, v}) -> {k, Enum.count(v)} end)
			|> Enum.max_by(fn({title, count}) -> count end)

			node |> Map.put(:title, best_title)
		else
			node
		end

		node
		|> Map.put(:votes, votes)
		|> Map.put(:results, results)
		|> Map.put(:all_results, Results.from_votes(votes, inverse_delegations, calculation_opts))
	end
	
	def load_references(node, calculation_opts, current_depth \\ nil) do
		depth = if current_depth == nil do calculation_opts.depth else current_depth end
		if depth > 0 do
			reference_nodes = ReferenceRepo.get_references(node, calculation_opts)

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
			inverse_reference_nodes = ReferenceRepo.get_inverse_references(node, calculation_opts)

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
end