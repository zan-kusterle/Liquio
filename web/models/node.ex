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
		ends_with = Enum.find(Map.keys(choice_types), & value_spaces |> String.downcase |> String.ends_with?(&1 |> String.downcase))

		{title, choice_type} = if ends_with == nil do
			{value_spaces, nil}
		else
			{String.slice(value_spaces, 0, String.length(value_spaces) - String.length(ends_with)), to_string(choice_types[ends_with])}
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
			|> Enum.map(& Node.from_key(&1) |> Node.preload(calculation_opts))
			|> Enum.filter(& &1.choice_type != nil)
			|> Enum.sort_by(& -(&1.results.turnout_ratio + 0.05 * Enum.count(&1.references)))

			node = Node.new("", nil) |> Map.put(:references, nodes) |> Map.put(:calculation_opts, calculation_opts)

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
		|> Enum.map(& Node.from_key(&1) |> Node.preload(calculation_opts))

		Node.new("Results for '#{query}'", nil) |> Map.put(:references, nodes) |> Map.put(:calculation_opts, calculation_opts)
	end

	def preload(node, calculation_opts) do
		preload(node, calculation_opts, nil)
	end

	def preload(node, calculation_opts, user) do
		key = {
			{"nodes", {node.key, node.reference_key}, calculation_opts.datetime},
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
			node = node |> preload_without_cache(calculation_opts, user)
			ResultsCache.set(key, node)
			node
		end
	end

	def preload_without_cache(node, calculation_opts, user) do
		node
		|> preload_references(calculation_opts)
		|> preload_inverse_references(calculation_opts)
		|> preload_results(calculation_opts)
		|> preload_own_vote(user)
		|> preload_own_contribution(user)
	end

	defp preload_results(node, calculation_opts) do
		node = if not Map.has_key?(node, :contributions) do
			node |> preload_contributions(calculation_opts)
		else
			node
		end

		results = AggregateContributions.aggregate(node.contributions, calculation_opts)
		node = Map.put(node, :results, results |> preload_results_embed)

		node
	end

	defp preload_contributions(node, calculation_opts) do
		node = if not Map.has_key?(node, :topics) do
			node |> preload_inverse_references(calculation_opts, depth: 0)
		else
			node
		end

		node = Map.put(node, :calculation_opts, calculation_opts)

		votes = GetData.get_votes(node.key, calculation_opts.datetime, node.reference_key)
		node = if not Enum.empty?(votes) do
			{best_title, _count} = votes
			|> Map.values
			|> Enum.group_by(& &1.title)
			|> Enum.map(fn({k, v}) -> {k, Enum.count(v)} end)
			|> Enum.max_by(fn({title, count}) -> count end)

			node |> Map.put(:title, best_title) |> update_keys
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
			|> Map.put(:results, results |> preload_results_embed)
		end)

		contributions = contributions
		|> Enum.map(fn(contribution) ->
			if contribution.choice_type == "time_quantity" do
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

	defp preload_references(node, calculation_opts, options \\ []) do
		%{depth: depth} = [depth: 1] |> Keyword.merge(options) |> Enum.into(Map.new)

		reference_nodes = from(v in Vote, where: v.key == ^node.key and not is_nil(v.reference_key) and v.is_last == true and not is_nil(v.data))
		|> Repo.all
		|> Enum.group_by(& &1.reference_key)
		|> prepare_reference_nodes(calculation_opts)

		reference_nodes = if depth >= 1 do
			reference_nodes |> Enum.map(fn(reference_node) ->
				reference_node |> preload_references(calculation_opts, depth: depth - 1)
			end)
		else
			reference_nodes
		end

		Map.put(node, :references, reference_nodes)
	end

	defp preload_inverse_references(node, calculation_opts, options \\ []) do
		if node.choice_type == nil do
			node = Map.put(node, :inverse_references, [])
			node = Map.put(node, :topics, [])
			node
		else
			%{depth: depth} = [depth: 1] |> Keyword.merge(options) |> Enum.into(Map.new)			

			inverse_reference_nodes = from(v in Vote, where: v.reference_key == ^node.key and v.is_last == true and not is_nil(v.data))
			|> Repo.all
			|> Enum.group_by(& &1.key)
			|> prepare_reference_nodes(calculation_opts)

			inverse_reference_nodes = if depth >= 1 do
				inverse_reference_nodes |> Enum.map(fn(inverse_reference_node) ->
					inverse_reference_node |> preload_references(calculation_opts, depth: depth - 1)
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
		end
	end

	def preload_own_vote(node, user) do
		vote = if user do Vote.current_by(node, user) else nil end

		node
		|> Map.put(:own_vote, vote)
	end

	def preload_own_contribution(node, user) do
		contribution = if user != nil and Map.get(node, :own_vote) != nil do
			c = if Map.has_key?(node, :contributions) do Enum.find(node.contributions, & &1.identity.id == user.id) else nil end
			c = if c == nil do
				node.own_vote
				|> GetData.prepare_vote
				|> Map.put(:voting_power, 0.0)
				|> Map.put(:identity, user)
			else
				c
			end
			results = AggregateContributions.aggregate_single(c)
			c
			|> Map.put(:results, results |> preload_results_embed)
		else
			nil
		end

		node
		|> Map.put(:own_contribution, contribution)
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

		base |> String.trim |> String.replace(" ", "-")
		|> URI.encode |> String.replace("/", "%2F") |> String.replace(":", "%3A") |> String.replace("?", "%3F") |> String.replace("=", "%3D") |> String.replace("&", "%26")
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
			from_key(key)
			|> preload_results(calculation_opts)
			|> Map.put(:reference_result, result)
			|> Map.put(:references, [])
		end)
		|> Enum.sort_by(& -&1.reference_result.by_keys["relevance"].mean)
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