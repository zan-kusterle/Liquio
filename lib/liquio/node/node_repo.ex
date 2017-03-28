defmodule Liquio.NodeRepo do
	alias Liquio.{Node, Vote, ResultsCache, NodeLoaders, Repo}

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
			node = NodeLoaders.load(node, calculation_opts, user)
			ResultsCache.set(key, node)
			node
		end
	end

	def invalidate_cache(node) do
		ResultsCache.unset({"nodes", node.group_key})
		if node.reference_path != nil do
			ResultsCache.unset({"nodes", Node.get_group_key(node.path, nil)})
			ResultsCache.unset({"nodes", Node.get_group_key(node.reference_path, nil)})
		end
	end
end