defmodule Liquio.ReferenceRepo do
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Repo, Delegation, Node, NodeRepo, Reference, ReferenceVote, ResultsCache, Results, CalculateResults}
	
	def load(reference, calculation_opts) do
		load(reference, calculation_opts, nil)
	end
	def load(reference, calculation_opts, user) do
		key = {
			{"references", Reference.group_key(reference), calculation_opts.datetime},
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
			reference = load_latest(reference, calculation_opts, user)
			ResultsCache.set(key, reference)
			reference
		end
	end

	def invalidate_cache(reference) do
		ResultsCache.unset({"references", {Enum.join(reference.path, "/"), Enum.join(reference.reference_path, "/")}})
		ResultsCache.unset({"nodes", {Enum.join(reference.path, "/"), nil}})
		ResultsCache.unset({"nodes", {Enum.join(reference.reference_path, "/"), nil}})
	end

	def load_latest(reference, calculation_opts, user) do		
		reference = reference
		|> load_results(calculation_opts, user)
		|> load_nodes(calculation_opts, user)

		reference
	end

	def load_nodes(reference, calculation_opts, user) do
		reference
		|> Map.put(:node, Node.new(reference.path) |> NodeRepo.load_results(calculation_opts, user))
		|> Map.put(:reference_node, Node.new(reference.reference_path) |> NodeRepo.load_results(calculation_opts, user))
	end
	
	def load_results(reference, calculation_opts, user) do
		votes = ReferenceVote.get_at_datetime(reference.path, reference.reference_path, calculation_opts.datetime) |> Repo.preload([:identity])
		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)
		results = Results.from_reference_votes(votes, inverse_delegations, calculation_opts)		

		own_vote = if Map.has_key?(reference, :own_vote) do
			reference.own_vote
		else
			if user do ReferenceVote.current_by(user, reference) else nil end
		end
		own_results = if own_vote do
			own_vote = own_vote |> Repo.preload([:identity])
			Results.from_reference_votes([own_vote], inverse_delegations, calculation_opts)
		else
			nil
		end

		reference
		|> Map.put(:results, results)
		|> Map.put(:own_vote, own_vote)
		|> Map.put(:own_results, own_results)
		|> Map.put(:calculation_opts, calculation_opts)
	end
	
	def get_references(node, calculation_opts) do
		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)

		ReferenceVote.get_at_datetime(node.path, nil, calculation_opts.datetime)
		|> Repo.preload([:identity])
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
		|> Repo.preload([:identity])
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
			result.total > 0 and result.turnout_ratio >= calculation_opts[:reference_minimum_turnout]
		end)
	end
end