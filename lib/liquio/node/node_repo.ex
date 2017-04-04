defmodule Liquio.NodeRepo do
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Node, Vote, ResultsCache, ReferenceRepo, Repo, CalculateResults, Results}

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
		ResultsCache.unset({"nodes", {Enum.join(node.path, "/"), nil}})
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

	def load_results(node, calculation_opts) do
		node = if not Map.has_key?(node, :topics) do
			node |> ReferenceRepo.load_inverse_references(calculation_opts, 1)
		else
			node
		end

		votes = Vote.get_votes(node.path, calculation_opts.datetime)
		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)
		contributions = CalculateResults.calculate(votes, inverse_delegations, calculation_opts.trust_metric_ids, node.topics) |> Repo.preload([:identity])
		results = Results.from_contributions(contributions, calculation_opts)

		node = if not Enum.empty?(results.contributions) do
			{best_title, _count} = results.contributions
			|> Enum.map(& Enum.join(&1.path, "/"))
			|> Enum.group_by(& &1)
			|> Enum.map(fn({k, v}) -> {k, Enum.count(v)} end)
			|> Enum.max_by(fn({title, count}) -> count end)

			node |> Node.put_title(best_title)
		else
			node
		end

		Map.put(node, :results, results)
	end
end