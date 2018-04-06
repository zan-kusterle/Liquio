defmodule Liquio.Node do
	alias Liquio.{Node, Delegation, Vote, ReferenceVote, Reference, Repo, Results}

	@enforce_keys [:path]
	defstruct [:path]

	def new(path) do
		%Node{path: path}
	end
	
	def decode(key) do
		key = String.replace(key, "://", ":")
		%Node{
			path: key |> String.trim(" ") |> String.split("/")
		}
	end

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
			|> Enum.map(& %{:path => &1.path, :results => &1.results, :references_count => Enum.count(&1.references)})

			Cachex.set(:references, key, %{
				:references => latest,
				:inverse_references => []
			}, ttl: :timer.seconds(Application.get_env(:liquio, :results_cache_seconds)))

			latest
		end

		references = reference_results
		|> Enum.filter(& &1.results.turnout_ratio > 0.0)
		|> Enum.sort_by(& -&1.references_count)
		|> Enum.map(& %{
			results: %{:average => &1.results.turnout_ratio},
			reference_node: &1 |> Map.drop([:references, :inverse_references]),
			node: nil
		})
		
		node = Node.new([])
		|> Map.put(:references, references)
		|> Map.put(:calculation_opts, calculation_opts)

		node
	end

	def search(query, calculation_opts) do
		references = Vote
		|> Vote.search(query)
		|> Repo.all
		|> Enum.map(& &1.path)
		|> Enum.uniq
		|> Enum.map(& Node.new(&1) |> load(calculation_opts))
		|> Enum.sort_by(& -Enum.count(&1.references))
		|> Enum.map(& %{
			results: %{:average => &1.results.turnout_ratio},
			reference_node: &1 |> Map.drop([:references, :inverse_references]),
			node: nil
		})

		Node.new(["Results", query])
		|> Map.put(:references, references)
		|> Map.put(:calculation_opts, calculation_opts)
	end

	def load(node, calculation_opts) do
		load(node, calculation_opts, calculation_opts.depth)
	end
	def load(node, calculation_opts, depth) do
		node = node
		|> load_results(calculation_opts, depth)
		|> Map.put(:calculation_opts, calculation_opts)
		node
	end

	defp load_results(node, calculation_opts, depth) do
		calculation_opts = calculation_opts |> Map.put(:topics, Map.get(node, :topics))

		votes = Vote.get_at_datetime(node.path, calculation_opts.datetime) |> Repo.preload([:signature])
		|> Enum.filter(& MapSet.member?(calculation_opts.trust_usernames, &1.username))

		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)
		|> Enum.filter(fn({username, v}) -> MapSet.member?(calculation_opts.trust_usernames, username) end)
		|> Enum.into(%{})

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

		node = if depth > 0 do
			cache_data = Cachex.get!(:references, {node.path, calculation_opts.trust_usernames})
			%{:references => reference_results, :inverse_references => inverse_reference_results} = if cache_data do
				cache_data
			else
				references = ReferenceVote.get_references(node, calculation_opts)
				|> Enum.map(& Reference.load(&1, calculation_opts))
				|> Enum.map(fn(reference) ->
					for_choice_results = votes
					|> Enum.filter(fn(vote) ->
						Enum.find(reference.results.votes, & &1.username == vote.username) != nil
					end)
					|> Results.from_votes(inverse_delegations, calculation_opts)

					%{:path => reference.reference_node.path, :results => reference.results, :for_choice_results => for_choice_results}
				end)
				|> Enum.filter(& &1.results.turnout_ratio > 0.2 and &1.results.average >= 0.5)
					
				inverse_references = ReferenceVote.get_inverse_references(node, calculation_opts)
				|> Enum.map(& Reference.load(&1, calculation_opts))
				|> Enum.map(& %{:path => &1.node.path, :results => &1.results})
				|> Enum.filter(& &1.results.turnout_ratio > 0.2 and &1.results.average >= 0.5)
				
				data = %{
					:references => references,
					:inverse_references => inverse_references
				}
				Cachex.set(:references, {node.path, calculation_opts.trust_usernames}, data, ttl: :timer.seconds(Application.get_env(:liquio, :results_cache_seconds)))
				data
			end

			references = reference_results
			|> Enum.map(fn(%{:path => path, :results => results, :for_choice_results => for_choice_results}) ->
				%{
					results: results,
					reference_node: Node.new(path) |> load(calculation_opts, depth - 1),
					node: node,
					for_choice_results: for_choice_results
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
		else
			node
		end	
		
		node
		|> Map.put(:results, Results.from_votes(votes, inverse_delegations, calculation_opts))
	end




	def get_references(node, calculation_opts) do
		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)

		ReferenceVote.get_at_datetime(node.path, nil, calculation_opts.datetime)
		|> Repo.preload([:signature])
		|> Enum.group_by(& &1.reference_path)
		|> prepare_reference_nodes(inverse_delegations, calculation_opts)
		|> Enum.map(fn({reference_path, result}) ->
			Reference.new(node.path, reference_path)
			|> Map.put(:results, result)
			|> Map.put(:node, node)
		end)
		|> Enum.sort_by(& -&1.results.average)
	end
	
	def get_inverse_references(node, calculation_opts) do
		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)

		ReferenceVote.get_at_datetime(nil, node.path, calculation_opts.datetime)
		|> Repo.preload([:signature])
		|> Enum.group_by(& &1.path)
		|> prepare_reference_nodes(inverse_delegations, calculation_opts)
		|> Enum.map(fn({path, result}) ->
			Reference.new(path, node.path)
			|> Map.put(:results, result)
			|> Map.put(:reference_node, node)
		end)
		|> Enum.sort_by(& -&1.results.average)
	end

	defp prepare_reference_nodes(keys_with_votes, inverse_delegations, calculation_opts) do
		keys_with_votes
		|> Enum.map(fn({k, votes}) ->
			{k, Results.from_reference_votes(votes, inverse_delegations, calculation_opts)}
		end)
		|> Enum.filter(fn({_k, result}) ->
			result.voting_power > 0 and result.turnout_ratio >= calculation_opts[:reference_minimum_turnout]
		end)
	end

	#Reference
	def load(reference, calculation_opts) do
		reference
		|> Map.put(:node, Node.new(reference.path) |> Node.load(calculation_opts, 0))
		|> Map.put(:reference_node, Node.new(reference.reference_path) |> Node.load(calculation_opts, 0))
		|> load_results(calculation_opts)
		|> Map.put(:calculation_opts, calculation_opts)
	end
	
	defp load_results(reference, calculation_opts) do
		votes = ReferenceVote.get_at_datetime(reference.path, reference.reference_path, calculation_opts.datetime) |> Repo.preload([:signature])
		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)
		results = Results.from_reference_votes(votes, inverse_delegations, calculation_opts)

		reference
		|> Map.put(:results, results)
	end



end
