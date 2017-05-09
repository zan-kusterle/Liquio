defmodule Liquio.NodeRepo do
	alias Liquio.{Node, Delegation, Vote, VoteRepo, ReferenceRepo, Repo, Results}

	def all(calculation_opts) do
		key = {:everything, calculation_opts.trust_metric_url}

		reference_results = Cachex.get!(:references, key)
		reference_results = if reference_results do
			reference_results
		else
			latest = Vote
			|> Repo.all
			|> Enum.map(& &1.path)
			|> Enum.uniq
			|> Enum.map(& Node.new(&1) |> load(calculation_opts, nil))
			|> Enum.map(& %{:path => &1.path, :results => &1.results})

			Cachex.set(:references, key, latest, ttl: :timer.seconds(Application.get_env(:liquio, :results_cache_seconds)))

			latest
		end

		references = reference_results
		|> Enum.map(& %{
			results: %{:relevance => &1.results.turnout_ratio, :latest_contributions => []},
			reference_node: &1 |> Map.drop([:references, :inverse_references]),
			node: nil
		})
		|> Enum.sort_by(& -&1.results.relevance)
		
		node = Node.new([])
		|> Map.put(:references, references)
		|> Map.put(:calculation_opts, calculation_opts)

		node
	end

	def search(query, calculation_opts) do
		references = Vote
		|> VoteRepo.search(query)
		|> Repo.all
		|> Enum.map(& &1.path)
		|> Enum.uniq
		|> Enum.map(& Node.new(&1) |> load(calculation_opts, nil))
		|> Enum.map(& Map.put(&1, :turnout, &1.results.by_units |> Enum.map(fn({_, v}) -> v.turnout_ratio end) |> Enum.sum))
		|> Enum.map(& %{
			results: %{:relevance => &1.turnout + 0.05 * Enum.count(&1.references), :latest_contributions => []},
			reference_node: &1 |> Map.drop([:references, :inverse_references]),
			node: nil
		})
		|> Enum.sort_by(& -&1.results.relevance)

		Node.new(["Results for #{query}"])
		|> Map.put(:references, references)
		|> Map.put(:calculation_opts, calculation_opts)
	end

	def load(node, calculation_opts) do
		load(node, calculation_opts, nil)
	end
	def load(node, calculation_opts, user) do
		load(node, calculation_opts, user, calculation_opts.depth)
	end
	def load(node, calculation_opts, user, depth) do
		node = node
		|> load_references(calculation_opts, depth, MapSet.new)
		|> load_inverse_references(calculation_opts, depth, MapSet.new)
		|> load_results(calculation_opts)
		|> Map.put(:calculation_opts, calculation_opts)

		node = if depth == 0 do
			node |> Map.drop([:inverse_references, :topics])
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

		node = node
		|> Map.put(:own_votes, own_votes)
		|> Map.put(:own_results, Results.from_votes(own_votes))

		node
	end

	defp load_results(node, calculation_opts) do
		node = Map.put(node, :topics, [])
		node = if not Map.has_key?(node, :topics) do
			node |> load_inverse_references(calculation_opts, 1, MapSet.new)
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
			|> Enum.max_by(fn({_title, count}) -> count end)

			node |> Map.put(:title, best_title)
		else
			node
		end
		
		node
		|> Map.put(:votes, votes)
		|> Map.put(:results, Results.from_votes(votes, inverse_delegations, calculation_opts))
	end
	
	defp load_references(node, calculation_opts, depth, visited) when depth == 0 do Map.put(node, :references, nil) end
	defp load_references(node, calculation_opts, depth, visited) do
		key = {node.path, calculation_opts.trust_usernames}

		reference_results = Cachex.get!(:references, key)
		reference_results = if reference_results do
			reference_results
		else
			data = ReferenceRepo.get_references(node, calculation_opts)
			|> Enum.map(& ReferenceRepo.load(&1, calculation_opts, nil))
			|> Enum.map(& %{:path => &1.reference_node.path, :results => &1.results})
			
			Cachex.set(:references, key, data, ttl: :timer.seconds(Application.get_env(:liquio, :results_cache_seconds)))
			data
		end

		references = if false and not MapSet.member?(visited, node.path) do
			visited = MapSet.put(visited, node.path)

			references = reference_results
			|> Enum.map(fn(%{:path => path, :results => results}) ->
				%{
					results: results,
					reference_node: node,
					node: Node.new(path) |> load(calculation_opts)
				}
			end)

			if depth > 1 do
				references |> Enum.map(fn(reference) ->
					Map.put(reference, :reference_node, reference.reference_node |> load_references(calculation_opts, depth - 1, visited) |> load_inverse_references(calculation_opts, 1, visited))
				end)
			else
				references
			end
		else
			[]
		end

		node
		|> Map.put(:references, references)
	end
	
	defp load_inverse_references(node, calculation_opts, depth, visited) when depth == 0 do
		node |> Map.put(:inverse_references, nil) |> Map.put(:topics, nil)
	end
	defp load_inverse_references(node, calculation_opts, depth, visited) do
		key = {node.path, calculation_opts.trust_metric_url}

		inverse_reference_results = Cachex.get!(:inverse_references, key)
		inverse_reference_results = if inverse_reference_results do
			inverse_reference_results
		else
			data = ReferenceRepo.get_inverse_references(node, calculation_opts)
			|> Enum.map(& ReferenceRepo.load(&1, calculation_opts, nil))
			|> Enum.map(& %{:path => &1.node.path, :results => &1.results})
			Cachex.set(:inverse_references, key, data, ttl: :timer.seconds(Application.get_env(:liquio, :results_cache_seconds)))
			data
		end
				
		inverse_references = if false and not MapSet.member?(visited, node.path) do
			visited = MapSet.put(visited, node.path)

			inverse_references = inverse_reference_results
			|> Enum.map(fn(%{:path => path, :results => results}) ->
				%{
					results: results,
					reference_node: Node.new(path) |> load(calculation_opts),
					node: node
				}
			end)

			inverse_references = if depth > 1 do
				inverse_references |> Enum.map(fn(inverse_reference) ->
					Map.put(inverse_reference, :node, inverse_reference.node |> load_inverse_references(calculation_opts, depth - 1, visited) |> load_references(calculation_opts, 1, visited))
				end)
			else
				inverse_references
			end
		else
			[]
		end
		
		topics = inverse_references
		|> Enum.filter(& Enum.count(&1.node.path) == 1 and String.length(Enum.at(&1.node.path, 0)) <= 20)
		|> Enum.map(& Enum.at(&1.node.path, 0))

		node
		|> Map.put(:topics, topics)
		|> Map.put(:inverse_references, inverse_references)
	end
end