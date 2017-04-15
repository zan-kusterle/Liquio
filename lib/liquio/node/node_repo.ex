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
			|> Enum.map(& Map.put(&1, :turnout, &1.results.by_units |> Enum.map(fn({_, v}) -> v.turnout_ratio end) |> Enum.sum))
			|> Enum.sort_by(& -(&1.turnout + 0.05 * Enum.count(&1.references)))
			|> Enum.map(& Map.drop(&1, [:references, :inverse_references]))
			
			node = Node.new([""])
			|> Map.put(:references, Enum.map(nodes, & %{results: %{:relevance => 0.8, :contributions => []}, node: nil, reference_node: &1}))
			|> Map.put(:calculation_opts, calculation_opts)

			ResultsCache.set(key, node)
			node
		end
	end

	def search(query, calculation_opts) do
		nodes = Vote
		|> VoteRepo.search(query)
		|> Repo.all
		|> Enum.map(& &1.path)
		|> Enum.uniq
		|> Enum.map(& Node.new(&1) |> load(calculation_opts |> Map.put(:depth, 0), nil))

		Node.new(["Results for #{query}"])
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
		|> load_results(calculation_opts, user)

		node = if calculation_opts.depth == 0 do
			node |> Map.drop([:inverse_references, :topics])
		else
			node
		end

		node
	end

	def load_results(node, calculation_opts, user) do
		node = Map.put(node, :topics, [])
		node = if not Map.has_key?(node, :topics) do
			node |> load_inverse_references(calculation_opts, 1)
		else
			node
		end
		calculation_opts = calculation_opts |> Map.put(:topics, node.topics)

		votes = VoteRepo.get_at_datetime(node.path, calculation_opts.datetime) |> Repo.preload([:identity])

		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)

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

		own_votes = if Map.has_key?(node, :own_votes) do
			node.own_votes
		else
			if user do
				VoteRepo.current_by(user, node)
			else
				[]
			end
		end
		own_votes = own_votes |> Repo.preload([:identity])
		
		node
		|> Map.put(:votes, votes)
		|> Map.put(:results, Results.from_votes(votes, inverse_delegations, calculation_opts))
		|> Map.put(:own_votes, own_votes)
		|> Map.put(:own_results, Results.from_votes(own_votes, inverse_delegations, calculation_opts))
	end
	
	def load_references(node, calculation_opts, current_depth \\ nil) do
		depth = if current_depth == nil do calculation_opts.depth else current_depth end
		if depth > 0 do
			reference_nodes = ReferenceRepo.get_references(node, calculation_opts)
			|> Enum.map(& &1 |> ReferenceRepo.load_nodes(calculation_opts, nil))

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
			|> Enum.map(& ReferenceRepo.load_nodes(&1, calculation_opts, nil))


			inverse_reference_nodes = if depth > 1 do
				inverse_reference_nodes |> Enum.map(fn(inverse_reference_node) ->
					inverse_reference_node |> load_inverse_references(calculation_opts, depth: depth - 1) |> load_references(calculation_opts, 1)
				end)
			else
				inverse_reference_nodes
			end

			topics = inverse_reference_nodes
			|> Enum.filter(& Enum.count(&1.path) == 1 and String.length(Enum.at(&1.path, 0)) <= 20)
			|> Enum.map(& Enum.at(&1.path, 0))

			node = Map.put(node, :inverse_references, inverse_reference_nodes)
			node = Map.put(node, :topics, topics)

			node
		else
			node
		end
	end
end