defmodule Liquio.NodeRepo do
	import Ecto
	import Ecto.Query, only: [from: 1, from: 2]
	alias Liquio.{Node, Identity, Vote, ResultsCache, Repo}
	alias Liquio.Results.{GetData, CalculateContributions, AggregateContributions}

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
			{"nodes", {node.key, node.reference_key}, calculation_opts.datetime},
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
			node = node |> load_without_cache(calculation_opts, user)
			ResultsCache.set(key, node)
			node
		end
	end
	
	def load_own_contribution(node, user) do
		vote = if Map.has_key?(node, :own_vote) do
			node.own_vote
		else
			if user do Vote.current_by(node, user) else nil end
		end

		contribution = if vote do
			contribution = if Map.has_key?(node, :contributions) and user != nil do
				Enum.find(node.contributions, & &1.identity.id == user.id)
			else
				nil
			end

			contribution = if contribution do
				contribution
			else
				vote
				|> GetData.prepare_vote
				|> Map.put(:voting_power, 0.0)
				|> Map.put(:identity, user)
			end
			
			results = AggregateContributions.aggregate_single(contribution)
			contribution
			|> Map.put(:results, results |> load_results_embed)
		else
			nil
		end

		node
		|> Map.put(:own_vote, vote)
		|> Map.put(:own_contribution, contribution)
	end

	defp load_without_cache(node, calculation_opts, user) do
		node = node
		|> load_references(calculation_opts)
		|> load_inverse_references(calculation_opts)
		|> load_results(calculation_opts)
		|> load_own_contribution(user)

		if calculation_opts.depth == 0 do
			node |> Map.drop([:inverse_references, :topics])
		else
			node
		end
	end

	defp load_results(node, calculation_opts) do
		node = if not Map.has_key?(node, :contributions) do
			node |> load_contributions(calculation_opts)
		else
			node
		end

		results = AggregateContributions.aggregate(node.contributions, calculation_opts)
		node = Map.put(node, :results, results |> load_results_embed)

		node
	end

	defp load_contributions(node, calculation_opts) do
		node = if not Map.has_key?(node, :topics) do
			node |> load_inverse_references(calculation_opts, 1)
		else
			node
		end

		node = Map.put(node, :calculation_opts, calculation_opts)

		votes = GetData.get_votes(node.key, node.reference_key, calculation_opts.datetime)
		node = if not Enum.empty?(votes) do
			{best_title, _count} = votes
			|> Map.values
			|> Enum.group_by(& &1.title)
			|> Enum.map(fn({k, v}) -> {k, Enum.count(v)} end)
			|> Enum.max_by(fn({title, count}) -> count end)

			node |> Node.put_title(best_title)
		else
			node
		end

		direct_votes = if node.reference_key == nil do votes |> Enum.filter(fn({k, v}) -> v.reference_key == nil end) |> Enum.into(%{}) else votes end
		inverse_delegations = GetData.get_inverse_delegations(calculation_opts.datetime)
		contributions = CalculateContributions.calculate(direct_votes, inverse_delegations, calculation_opts.trust_metric_ids, MapSet.new(node.topics))

		identity_ids = Enum.map(contributions, & &1.identity.id)
		identities = from(i in Identity, where: i.id in ^identity_ids)
		|> Repo.all
		|> Enum.into(%{}, & {&1.id, &1})

		contributions = contributions |> Enum.map(fn(contribution) ->
			contribution = Map.put(contribution, :identity, identities[contribution.identity.id])
			results = AggregateContributions.aggregate_single(contribution)
			
			contribution
			|> Map.put(:results, results |> load_results_embed)
		end)

		contributions = contributions
		|> Enum.map(fn(contribution) ->
			if contribution.choice_type == "time_series" do
				points = contribution.choice
				|> Enum.map(fn({time_key, value}) ->
					case Integer.parse(time_key) do
						{year, ""} -> {Timex.to_date({year, 1, 1}), value}
						:error -> nil
					end
				end)
				|> Enum.filter(& &1 != nil)
				Map.put(contribution, :points, points)
			else
				contribution
			end
		end)

		Map.put(node, :contributions, contributions)
	end

	defp load_references(node, calculation_opts, current_depth \\ nil) do
		depth = if current_depth == nil do calculation_opts.depth else current_depth end
		if depth > 0 do
			reference_nodes = from(v in Vote, where: v.key == ^node.key and not is_nil(v.reference_key) and v.is_last == true and not is_nil(v.data))
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

	defp load_inverse_references(node, calculation_opts, current_depth \\ nil) do
		depth = if current_depth == nil do calculation_opts.depth else current_depth end
		if depth > 0 do
			inverse_reference_nodes = from(v in Vote, where: v.reference_key == ^node.key and v.is_last == true and not is_nil(v.data))
			|> Repo.all
			|> Enum.group_by(& &1.key)
			|> prepare_reference_nodes(calculation_opts)

			if depth > 1 do
				inverse_reference_nodes |> Enum.map(fn(inverse_reference_node) ->
					inverse_reference_node |> load_inverse_references(calculation_opts, depth: depth - 1)
				end)
			else
				inverse_reference_nodes
			end

			topics = inverse_reference_nodes
			|> Enum.filter(& &1.choice_type == nil)
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
			votes = GetData.prepare_votes(votes)
			inverse_delegations = GetData.get_inverse_delegations(calculation_opts.datetime)
			contributions = CalculateContributions.calculate(votes, inverse_delegations, calculation_opts.trust_metric_ids, MapSet.new)
			results = AggregateContributions.aggregate(contributions, calculation_opts)
			{key, results}
		end)
		|> Enum.filter(fn({_key, result}) ->
			Map.has_key?(result.by_keys, "relevance") and result.total > 0 and result.turnout_ratio >= calculation_opts[:reference_minimum_turnout]
		end)
		|> Enum.map(fn({key, result}) ->
			Node.decode(key)
			|> load_results(calculation_opts)
			|> Map.put(:reference_result, result)
		end)
		|> Enum.sort_by(& -&1.reference_result.by_keys["relevance"].mean)
	end

	defp load_results_embed(results) do
		with_embed = results.by_keys
		|> Enum.map(fn({results_key, results_for_key}) ->
			embed_html = Phoenix.View.render_to_iodata(Liquio.Web.NodeView, "inline_results.html", results: results, results_key: results_key)
			|> :erlang.iolist_to_binary
			|> Liquio.HtmlHelper.minify
			|> String.replace("\"", "'")

			{results_key, results_for_key |> Map.put(:embed, embed_html)}
		end)
		|> Enum.into(%{})

		embed_whole = Phoenix.View.render_to_iodata(Liquio.Web.NodeView, "inline_results.html", results: results)
		|> :erlang.iolist_to_binary
		|> Liquio.HtmlHelper.minify
		|> String.replace("\"", "'")

		results |> Map.put(:by_keys, with_embed) |> Map.put(:embed, embed_whole)
	end
end