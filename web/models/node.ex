defmodule Liquio.Node do
	@enforce_keys [:choice_type, :key, :reference_key]
	defstruct [:title, :choice_type, :key, :reference_key]

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
			reference_key: reference_key
		}
	end

	def decode(value) do
		choice_types = %{
			"Probability" => :probability, 
			"Quantity" => :quantity,
			"Time Series" => :time_quantity
		}

		value_spaces = value |> String.replace("-", " ") |> String.replace("_", " ")
		ends_with = Enum.find(Map.keys(choice_types), & String.ends_with?(value_spaces, &1))

		node = if ends_with == nil do
			%{:title => value_spaces, :choice_type => nil}
		else
			%{:title => String.replace_suffix(value_spaces, ends_with, ""), :choice_type => to_string(choice_types[ends_with])}
		end
		node = Map.put(node, :reference_key, nil)
		node = Map.put(node, :title, node.title |> String.trim)
		node = Map.put(node, :key, get_key(node))

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

	def encode(node) do
		choice_types = %{
			"probability" => "Probability",
			"quantity" => "Quantity",
			"time_quantity" => "Time Series",
			nil => ""
		}

		"#{node.title} #{choice_types[node.choice_type]}" |> String.trim |> String.replace(" ", "-")
	end

	def from_key(key) do
		choice_types = %{
			"_probability" => :probability, 
			"_quantity" => :quantity,
			"_time series" => :time_quantity,
			"_" => nil
		}

		ends_with = Enum.find(Map.keys(choice_types), & String.ends_with?(key, &1))
		if ends_with == nil do
			title = key |> String.replace("_", " ") |> String.trim
			%Node{
				:title => title,
				:choice_type => nil,
				:key => key,
				:reference_key => nil
			}
		else
			title = key |> String.replace("_", " ") |> String.replace_trailing(ends_with, "") |> String.trim
			%Node{
				:title => title,
				:choice_type => to_string(choice_types[ends_with]),
				:key => key,
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

	defp get_key(node) do
		get_key(node.title, node.choice_type)
	end
	defp get_key(title, choice_type) do
		"#{title} #{choice_type}" |> String.downcase |> String.replace(" ", "_")
	end

	def preload(node, calculation_opts) do
		preload(node, calculation_opts, nil)
	end

	def preload(node, calculation_opts, user) do
		node
		|> preload_results(calculation_opts)
		|> preload_references(calculation_opts)
		|> preload_inverse_references(calculation_opts)
		|> preload_user_vote(user)
		|> preload_user_contribution(calculation_opts, user)
	end

	def preload_results(node, calculation_opts) do
		node = if not Map.has_key?(node, :contributions) do
			node |> preload_contributions(calculation_opts)
		else
			node
		end

		node = Map.put(node, :results, results_from_contributions(node.contributions, node.choice_type, calculation_opts))

		embed_html = Phoenix.View.render_to_iodata(Liquio.NodeView, "embed.html", poll: node)
		|> :erlang.iolist_to_binary
		|> Liquio.HtmlHelper.minify
		node = Map.put(node, :embed, embed_html)

		node
	end

	def preload_contributions(node, calculation_opts) do
		node = if not Map.has_key?(node, :topics) do
			node |> preload_inverse_references(calculation_opts)
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
			Map.put(contribution, :identity, Repo.get(Identity, contribution.identity_id))
		end)

		node = if not Enum.empty?(contributions) do
			{best_title, _count} = contributions
			|> Enum.group_by(& &1.title)
			|> Enum.map(fn({k, v}) -> {k, Enum.count(v)} end)
			|> Enum.max_by(fn({title, count}) -> count end)

			Map.put(node, :title, best_title)
		else
			node
		end

		Map.put(node, :contributions, contributions)
	end

	def preload_references(node, calculation_opts) do
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

			ResultsCache.set(key, reference_nodes)
			reference_nodes
		end

		Map.put(node, :references, reference_nodes)
	end

	def preload_inverse_references(node, calculation_opts) do
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

			ResultsCache.set(key, inverse_reference_nodes)
			inverse_reference_nodes
		end

		topics = inverse_reference_nodes
		|> Enum.filter(& &1.choice_type == nil)
		|> Enum.map(& &1.key)

		node = Map.put(node, :inverse_references, inverse_reference_nodes)
		node = Map.put(node, :topics, topics)
		node
	end

	defp prepare_reference_nodes(keys_with_votes, calculation_opts) do
		keys_with_votes
		|> Enum.map(fn({key, votes}) ->
			votes = GetData.prepare_votes(votes)
			inverse_delegations = GetData.get_inverse_delegations(calculation_opts.datetime)
			contributions = CalculateContributions.calculate(votes, inverse_delegations, calculation_opts.trust_metric_ids, MapSet.new)
			results = results_from_contributions(contributions, "probability", calculation_opts)
			{key, results}
		end)
		|> Enum.filter(fn({_key, result}) ->
			result.total > 0 and result.turnout_ratio >= calculation_opts[:reference_minimum_turnout]
		end)
		|> Enum.map(fn({key, result}) ->
			Node.from_key(key)
			|> preload_results(calculation_opts)
			|> Map.put(:reference_result, result)
		end)
		|> Enum.sort(&(&1.results.total > &2.results.total))
	end

	def preload_user_vote(node, user) do
		vote = if user do Vote.current_by(node, user) else nil end
		Map.put(node, :own_vote, vote)
	end

	defp preload_user_contribution(node, calculation_opts, user) do
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

		contribution = if user do Enum.find(node.contributions, & &1.identity.id == user.id) else nil end
		total_voting_power = node.contributions |> Enum.map(& &1.voting_power) |> Enum.sum

		user_contribution = if contribution == nil do
			nil
		else
			if node.choice_type == "time_quantity" do
				by_datetime = contribution.choice
				|> Enum.map(fn({time_key, value}) ->
					{year, ""} = Integer.parse(time_key)
					%{
						:total => 1,
						:turnout_ratio => 1,
						:datetime => Timex.to_date({year, 1, 1}),
						:mean => value
					}
				end)

				%{
					:total => contribution.voting_power,
					:turnout_ratio => contribution.voting_power / total_voting_power,
					:by_datetime => by_datetime
				}
			else
				%{
					:total => contribution.voting_power,
					:turnout_ratio => contribution.voting_power / total_voting_power,
					:mean => contribution.choice["main"]
				}
			end
		end
		
		Map.put(node, :own_contribution, user_contribution)
	end

	defp ensure_rounding_sums_to(numbers, precision, target) do
		rounded = Enum.map(numbers, & Float.round(&1, precision))
		off = target - Enum.sum(rounded)
		numbers
		|> Enum.sort_by(& Float.round(&1, precision) - &1)
		|> Enum.map(& Float.round(&1, precision))
	end

	defp results_from_contributions(contributions, choice_type, calculation_opts) do
		results = AggregateContributions.aggregate(contributions, calculation_opts.datetime, calculation_opts.vote_weight_halving_days, choice_type, calculation_opts.trust_metric_ids)

		results = if choice_type == "time_quantity" do
			results_with_datetime = results.by_keys
			|> Enum.map(fn({time_key, time_results}) ->
				{year, ""} = Integer.parse(time_key)
				Map.put(time_results, :datetime, Timex.to_date({year, 1, 1}))
			end)
			|> Enum.filter(fn(datetime_result) ->
				datetime_result.total >= calculation_opts.minimum_voting_power
			end)
			results |> Map.put(:by_datetime, results_with_datetime)
		else
			main_results = AggregateContributions.by_key(results.by_keys, "main")
			if main_results.total >= calculation_opts.minimum_voting_power do
				main_results
			else
				Map.put(main_results, :mean, nil)
			end
		end
	end
end