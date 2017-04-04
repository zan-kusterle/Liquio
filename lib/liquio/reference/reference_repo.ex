defmodule Liquio.ReferenceRepo do
	alias Liquio.{Repo, Reference, ReferenceVote, ResultsCache, Results}
	
	def load(reference, calculation_opts) do
		load(reference, calculation_opts, nil)
	end
	def load(reference, calculation_opts, user) do
		key = {
			{"nodes", Reference.group_key(reference), calculation_opts.datetime},
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
			if user do ReferenceVote.current_by(node, user) else nil end
		end

		contribution = if vote do
			contribution = if Map.has_key?(node, :results) and user != nil do
				Enum.find(node.results.contributions, & &1.identity.username == user.username)
			else
				nil
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
		votes = ReferenceVote.get_at_datetime(reference.path, reference.reference_path, calculation_opts.datetime)
		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)
		contributions = CalculateResults.calculate(votes, inverse_delegations, calculation_opts.trust_metric_ids, node.topics) |> Repo.preload([:identity])
		results = Results.from_contributions(contributions, calculation_opts)

		node
		|> Map.put(:results, results)
	end

end