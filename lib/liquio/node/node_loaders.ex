defmodule Liquio.NodeLoaders do
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Repo, Node, Vote, CalculateResults, Results}

	def load(node, calculation_opts, user) do
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

	defp load_results(node, calculation_opts) do
		node = if not Map.has_key?(node, :topics) do
			node |> load_inverse_references(calculation_opts, 1)
		else
			node
		end

		results = CalculateResults.calculate(node, calculation_opts)

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

	defp load_references(node, calculation_opts, current_depth \\ nil) do
		depth = if current_depth == nil do calculation_opts.depth else current_depth end
		if depth > 0 do
			reference_nodes = from(v in Vote, where: v.group_key == ^node.group_key and not is_nil(v.reference_path) and v.is_last == true and not is_nil(v.choice))
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
			inverse_reference_nodes = from(v in Vote, where: v.reference_path == ^node.path and v.is_last == true and not is_nil(v.choice))
			|> Repo.all
			|> Enum.group_by(& &1.key)
			|> prepare_reference_nodes(calculation_opts)

			inverse_reference_nodes = if depth > 1 do
				inverse_reference_nodes |> Enum.map(fn(inverse_reference_node) ->
					inverse_reference_node |> load_inverse_references(calculation_opts, depth: depth - 1) |> load_references(calculation_opts, 1)
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
			results = votes
			|> Enum.filter(& &1.filter_key == "relevance")
			|> CalculateResults.calculate_for_votes(calculation_opts)
			{key, results}
		end)
		|> Enum.filter(fn({_key, result}) ->
			result.total > 0 and result.turnout_ratio >= calculation_opts[:reference_minimum_turnout]
		end)
		|> Enum.map(fn({key, result}) ->
			Node.decode(key)
			|> load_results(calculation_opts)
			|> Map.put(:reference_result, result)
		end)
		|> Enum.sort_by(& -&1.reference_result.mean)
	end
end