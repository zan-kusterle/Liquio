defmodule Liquio.Node do
	@enforce_keys [:choice_type, :key, :reference_key]
	defstruct [:title, :choice_type, :key, :url_key, :reference_key]

	import Ecto
	import Ecto.Query, only: [from: 1, from: 2]
	alias Liquio.{Node, Identity, Vote, ResultsCache, Repo}
	alias Liquio.Results.{GetData, CalculateContributions, AggregateContributions}

	def new(title, choice_type) do new(title, choice_type, nil) end
	def new(title, choice_type, reference_key) do
		%Node{
			title: title,
			choice_type: choice_type,
			key: get_key(title, choice_type),
			url_key: get_url_key(title, choice_type),
			reference_key: reference_key
		}
	end

	def decode(value) do
		choice_types = %{
			"Probability" => :probability, 
			"Quantity" => :quantity,
			"Time Series" => :time_quantity
		}

		value_spaces = value |> URI.decode |> String.replace("-", " ") |> String.replace("_", " ")
		ends_with = Enum.find(Map.keys(choice_types), & String.ends_with?(value_spaces, &1))

		{title, choice_type} = if ends_with == nil do
			{value_spaces, nil}
		else
			{String.replace_suffix(value_spaces, ends_with, ""), to_string(choice_types[ends_with])}
		end
		node = Node.new(title |> String.trim(), choice_type, nil)

		if String.length(node.title) > 0 do
			node
		else
			nil
		end
	end

	def decode_many(value) do
		nodes = value
		|> String.split("_")
		|> Enum.filter(& String.length(&1) > 0)
		|> Enum.map(& decode(&1))
		|> Enum.filter(& &1 != nil)
	end

	def from_key(key) do
		choice_types = %{
			"_probability" => "probability", 
			"_quantity" => "quantity",
			"_time_quantity" => "time_quantity",
			"_" => nil
		}

		ends_with = Map.keys(choice_types) |> Enum.sort_by(& -String.length(&1)) |> Enum.find(& String.ends_with?(key, &1))
		if ends_with == nil do
			title = key |> String.replace("_", " ") |> String.trim
			%Node{
				:title => title,
				:choice_type => nil,
				:key => key,
				:url_key => get_url_key(title, nil),
				:reference_key => nil
			}
		else
			title = key |> String.replace_trailing(ends_with, "") |> String.replace("_", " ") |> String.trim
			%Node{
				:title => title,
				:choice_type => choice_types[ends_with],
				:key => key,
				:url_key => get_url_key(title, choice_types[ends_with]),
				:reference_key => nil
			}
		end
	end

	def for_reference_key(node, reference_key) do
		reference_key = if reference_key != "" do reference_key else nil end
		node = node
		|> Map.put(:reference_key, reference_key)
		
		node = Map.put(node, :key, get_key(node))
		node
	end

	def update_key(node) do
		Map.put(node, :key, get_key(node))
	end

	def preload(node, calculation_opts) do
		preload(node, calculation_opts, nil)
	end

	def preload(node, calculation_opts, user) do
		node
		|> preload_references(calculation_opts)
		|> preload_inverse_references(calculation_opts)
		|> preload_results(calculation_opts)
		|> preload_user_vote(user)
		|> preload_user_contribution(calculation_opts, user)
	end

	def preload_results(node, calculation_opts) do
		node = if not Map.has_key?(node, :contributions) do
			node |> preload_contributions(calculation_opts)
		else
			node
		end

		results = AggregateContributions.aggregate(node.contributions, calculation_opts)
		node = Map.put(node, :results, results |> preload_results_embed)

		node
	end

	def preload_contributions(node, calculation_opts) do
		node = if not Map.has_key?(node, :topics) do
			node |> preload_inverse_references(calculation_opts, depth: 0)
		else
			node
		end

		node = Map.put(node, :calculation_opts, calculation_opts)

		key = {
			{"contributions", {node.key, node.reference_key}, calculation_opts.datetime},
			{calculation_opts.trust_metric_url}
		}
		cache_results = ResultsCache.get(key)
		contributions = if cache_results do
			cache_results
		else
			votes = GetData.get_votes(node.key, calculation_opts.datetime, node.reference_key)
			inverse_delegations = GetData.get_inverse_delegations(calculation_opts.datetime)
			contributions = CalculateContributions.calculate(votes, inverse_delegations, calculation_opts.trust_metric_ids, MapSet.new(node.topics))
			ResultsCache.set(key, contributions)
			contributions
		end

		contributions = contributions |> Enum.map(fn(contribution) ->
			contribution = Map.put(contribution, :identity, Repo.get(Identity, contribution.identity.id))
			results = AggregateContributions.aggregate([contribution], calculation_opts)
			
			contribution
			|> Map.put(:results, results |> preload_results_embed)
		end)

		node = if not Enum.empty?(contributions) do
			{best_title, _count} = contributions
			|> Enum.group_by(& &1.title)
			|> Enum.map(fn({k, v}) -> {k, Enum.count(v)} end)
			|> Enum.max_by(fn({title, count}) -> count end)

			node |> Map.put(:title, best_title) |> update_keys
		else
			node
		end

		contributions = contributions
		
		|> Enum.map(fn(contribution) ->
			if contribution.choice_type == "time_quantity" do
				points = contribution.choice |> Enum.map(fn({time_key, value}) ->
					{year, ""} = Integer.parse(time_key)
					{Timex.to_date({year, 1, 1}), value}
				end)
				Map.put(contribution, :points, points)
			else
				contribution
			end
		end)

		Map.put(node, :contributions, contributions)
	end

	def preload_references(node, calculation_opts, options \\ []) do
		%{depth: depth} = [depth: 1] |> Keyword.merge(options) |> Enum.into(Map.new)

		key = {
			{"references", node.key, calculation_opts.datetime},
			{
				calculation_opts.trust_metric_url,
				calculation_opts.minimum_voting_power,
				calculation_opts.reference_minimum_turnout
			}
		}
		cache_results = ResultsCache.get(key)
		reference_nodes = if cache_results do
			cache_results
		else
			reference_nodes = from(v in Vote, where: v.key == ^node.key and not is_nil(v.reference_key) and v.is_last == true and not is_nil(v.data))
			|> Repo.all
			|> Enum.group_by(& &1.reference_key)
			|> prepare_reference_nodes(calculation_opts)

			if depth >= 1 do
				reference_nodes |> Enum.map(fn(reference_node) ->
					reference_node |> preload_references(calculation_opts, depth: depth - 1)
				end)
				ResultsCache.set(key, reference_nodes)
				reference_nodes
			else
				reference_nodes
			end
		end

		Map.put(node, :references, reference_nodes)
	end

	def preload_inverse_references(node, calculation_opts, options \\ []) do
		if node.choice_type == nil do
			node = Map.put(node, :inverse_references, [])
			node = Map.put(node, :topics, [])
			node
		else
			%{depth: depth} = [depth: 1] |> Keyword.merge(options) |> Enum.into(Map.new)			

			key = {
				{"inverse_references", node.key, calculation_opts.datetime},
				{
					calculation_opts.trust_metric_url,
					calculation_opts.minimum_voting_power,
					calculation_opts.reference_minimum_turnout
				}
			}
			cache_results = ResultsCache.get(key)
			inverse_reference_nodes = if cache_results do
				cache_results
			else
				inverse_reference_nodes = from(v in Vote, where: v.reference_key == ^node.key and v.is_last == true and not is_nil(v.data))
				|> Repo.all
				|> Enum.group_by(& &1.key)
				|> prepare_reference_nodes(calculation_opts)

				if depth >= 1 do
					inverse_reference_nodes |> Enum.map(fn(inverse_reference_node) ->
						inverse_reference_node |> preload_references(calculation_opts, depth: depth - 1)
					end)
					ResultsCache.set(key, inverse_reference_nodes)
					inverse_reference_nodes
				else
					inverse_reference_nodes
				end
			end

			topics = inverse_reference_nodes
			|> Enum.filter(& &1.choice_type == nil)
			|> Enum.map(& &1.key)

			node = Map.put(node, :inverse_references, inverse_reference_nodes)
			node = Map.put(node, :topics, topics)
			node
		end
	end

	def preload_user_vote(node, user) do
		vote = if user do Vote.current_by(node, user) else nil end
		Map.put(node, :own_vote, vote)
	end

	def preload_user_contribution(node, calculation_opts, user) do
		node = if not Map.has_key?(node, :own_vote) do
			node |> preload_user_vote(user)
		else
			node
		end
		node = if not Map.has_key?(node, :contributions) do
			node |> preload_contributions(calculation_opts)
		else
			node
		end

		user_contribution = if user do Enum.find(node.contributions, & &1.identity.id == user.id) else nil end
		node
		|> Map.put(:own_contribution, user_contribution)
	end

	defp update_keys(node) do
		node
		|> Map.put(:key, get_key(node))
		|> Map.put(:url_key, get_url_key(node))
	end

	defp get_key(node) do
		get_key(node.title, node.choice_type)
	end
	defp get_key(title, choice_type) do
		"#{title} #{choice_type}" |> String.downcase |> String.replace(" ", "_")
	end

	defp get_url_key(node) do
		get_url_key(node.title, node.choice_type)
	end
	defp get_url_key(title, choice_type) do
		base = if choice_type == nil do
			title
		else
			choice_types = %{
				"probability" => "Probability",
				"quantity" => "Quantity",
				"time_quantity" => "Time Series",
				nil => ""
			}
			"#{title} #{choice_types[choice_type]}"
		end

		base |> String.trim |> String.trim("/") |> String.replace(" ", "-") |> URI.encode |> String.replace("/", "%2F")
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
			result.total > 0 and result.turnout_ratio >= calculation_opts[:reference_minimum_turnout]
		end)
		|> Enum.map(fn({key, result}) ->
			Node.from_key(key)
			|> preload_results(calculation_opts)
			|> Map.put(:reference_result, result)
			|> Map.put(:references, [])
		end)
		|> Enum.sort(&(&1.results.total > &2.results.total))
	end

	defp preload_results_embed(results) do
		with_embed = results.by_keys
		|> Enum.map(fn({results_key, results_for_key}) ->
			embed_html = Phoenix.View.render_to_iodata(Liquio.NodeView, "inline_results.html", results: results, results_key: results_key)
			|> :erlang.iolist_to_binary
			|> Liquio.HtmlHelper.minify
			|> String.replace("\"", "'")

			{results_key, results_for_key |> Map.put(:embed, embed_html)}
		end)
		|> Enum.into(%{})

		embed_whole = Phoenix.View.render_to_iodata(Liquio.NodeView, "inline_results.html", results: results)
		|> :erlang.iolist_to_binary
		|> Liquio.HtmlHelper.minify
		|> String.replace("\"", "'")

		results |> Map.put(:by_keys, with_embed) |> Map.put(:embed, embed_whole)
	end
end