defmodule Liquio.NodeRepo do
	alias Liquio.{Node, Delegation, Vote, VoteRepo, ReferenceVote, ReferenceRepo, Repo, Results}

	def all(calculation_opts) do
		key = {:everything, calculation_opts.trust_metric_url}

		reference_results = Cachex.get!(:references, key)
		reference_results = if reference_results do
			%{:references => latest} = reference_results
			latest
		else
			latest = Vote
			|> Repo.all
			|> Enum.map(& &1.path)
			|> Enum.uniq
			|> Enum.map(& Node.new(&1) |> load(calculation_opts))
			|> Enum.map(& %{:path => &1.path, :results => &1.results})

			Cachex.set(:references, key, %{
				:references => latest,
				:inverse_references => []
			}, ttl: :timer.seconds(Application.get_env(:liquio, :results_cache_seconds)))

			latest
		end

		references = reference_results
		|> Enum.filter(& &1.results.turnout_ratio > 0.0)
		|> Enum.map(& %{
			results: %{:average => &1.results.turnout_ratio, :latest_contributions => []},
			reference_node: &1 |> Map.drop([:references, :inverse_references]),
			node: nil
		})
		|> Enum.sort_by(& -&1.results.average)
		
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
		|> Enum.map(& Node.new(&1) |> load(calculation_opts))
		|> Enum.map(& Map.put(&1, :turnout, &1.results.by_units |> Enum.map(fn({_, v}) -> v.turnout_ratio end) |> Enum.sum))
		|> Enum.map(& %{
			results: %{:average => &1.turnout + 0.05 * Enum.count(&1.references), :latest_contributions => []},
			reference_node: &1 |> Map.drop([:references, :inverse_references]),
			node: nil
		})
		|> Enum.sort_by(& -&1.results.average)

		Node.new(["Results", query])
		|> Map.put(:references, references)
		|> Map.put(:calculation_opts, calculation_opts)
	end

	def load(node, calculation_opts) do
		load(node, calculation_opts, calculation_opts.depth)
	end
	def load(node, calculation_opts, depth) do
		node = node |> Map.put(:calculation_opts, calculation_opts)
		node = node |> load_references(calculation_opts, depth)
		node = node |> load_results(calculation_opts)

		node = if depth == 0 do
			node |> Map.drop([:inverse_references, :topics])
		else
			node
		end

		node
	end

	defp load_results(node, calculation_opts) do
		calculation_opts = calculation_opts |> Map.put(:topics, Map.get(node, :topics))

		votes = VoteRepo.get_at_datetime(node.path, calculation_opts.datetime) |> Repo.preload([:signature])
		|> Enum.filter(& MapSet.member?(calculation_opts.custom_trust_usernames, &1.username))

		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)
		|> Enum.filter(& MapSet.member?(calculation_opts.custom_trust_usernames, &1.username))

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
	
	defp load_references(node, _, depth) when depth == 0 do node end
	defp load_references(node, calculation_opts, depth) do
		key = {node.path, calculation_opts.trust_usernames}

		reference_results = Cachex.get!(:references, key)
		%{:references => reference_results, :inverse_references => inverse_reference_results} = if reference_results do
			reference_results
		else
			references = ReferenceVote.get_references(node, calculation_opts)
			|> Enum.map(& ReferenceRepo.load(&1, calculation_opts))
			|> Enum.map(& %{:path => &1.reference_node.path, :results => &1.results})
			|> Enum.filter(& &1.results.turnout_ratio > 0.2 and &1.results.average >= 0.5)
				
			inverse_references = ReferenceVote.get_inverse_references(node, calculation_opts)
			|> Enum.map(& ReferenceRepo.load(&1, calculation_opts))
			|> Enum.map(& %{:path => &1.node.path, :results => &1.results})
			|> Enum.filter(& &1.results.turnout_ratio > 0.2 and &1.results.average >= 0.5)
			
			data = %{
				:references => references,
				:inverse_references => inverse_references
			}
			Cachex.set(:references, key, data, ttl: :timer.seconds(Application.get_env(:liquio, :results_cache_seconds)))
			data
		end

		references = reference_results
		|> Enum.map(fn(%{:path => path, :results => results}) ->
			%{
				results: results,
				reference_node: Node.new(path) |> load(calculation_opts, depth - 1),
				node: node
			}
		end)

		inverse_references = inverse_reference_results
		|> Enum.map(fn(%{:path => path, :results => results}) ->
			%{
				results: results,
				reference_node: node,
				node: Node.new(path) |> load(calculation_opts, depth - 1)
			}
		end)

		topics = inverse_references
		|> Enum.filter(& Enum.count(&1.node.path) == 1 and String.length(Enum.at(&1.node.path, 0)) <= 20)
		|> Enum.map(& Enum.at(&1.node.path, 0))

		node
		|> Map.put(:references, references)
		|> Map.put(:inverse_references, inverse_references)
		|> Map.put(:topics, topics)
	end
end