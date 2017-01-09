defmodule Liquio.Poll do
	use Liquio.Web, :model

	alias Liquio.Repo
	alias Liquio.Poll
	alias Liquio.Vote
	alias Liquio.TopicReference
	alias Liquio.ResultsCache
	alias Liquio.Results.GetData
	alias Liquio.Results.CalculateContributions
	alias Liquio.Results.AggregateContributions

	schema "polls" do
		field :kind, :string
		field :choice_type, :string
		field :title, :string

		field :latest_default_results, :map

		has_many :votes, Vote

		timestamps
	end
	
	def changeset(data, params) do
		params =
			if Map.has_key?(params, "title") and is_bitstring(params["title"]) do
				Map.put(params, "title", capitalize_title(params["title"]))
			else
				params
			end
		data
		|> cast(params, ["choice_type", "title"])
		|> validate_required(:title)
		|> validate_required(:choice_type)
		|> put_change(:kind, "custom")
	end

	def create(changeset) do
		Repo.insert(changeset)
	end

	def create(choice_type, title) do
		Repo.insert!(%Poll{
			:kind => "custom",
			:choice_type => to_string(choice_type),
			:title => capitalize_title(title),
		})
	end

	def force_get(choice_type, title) do
		query = from(p in Poll, where:
			p.kind == "custom" and
			p.choice_type == ^to_string(choice_type) and
			p.title == ^capitalize_title(title)
		)
		poll = query
		|> Ecto.Query.first
		|> Repo.one
		if poll == nil do
			Poll.create(choice_type, title)
		else
			poll
		end
	end

	def search(query, search_term) do
		from(p in query,
		where: fragment("? % ?", p.title, ^search_term),
		order_by: fragment("similarity(?, ?) DESC", p.title, ^search_term))
	end

	def all() do
		from(p in Poll, where: p.kind == "custom", order_by: [desc: p.id])
	end

	def by_default_topic(query, path) do
		from p in query,
		where:
			not is_nil(p.latest_default_results) and
			p.kind == "custom" and
			fragment("(?->'topics_with_parents')::jsonb \\? ?", p.latest_default_results, ^Enum.join(path, ">"))
	end

	def sorted_top(query) do
		from p in query,
		where: not is_nil(p.latest_default_results),
		order_by: [desc: fragment("1.0 * (?->'total')::text::float + 0.25 * (?->'references_count')::text::float", p.latest_default_results, p.latest_default_results)]
	end

	def sorted_new(query) do
		from p in query,
		where: not is_nil(p.latest_default_results),
		order_by: [desc: p.id]
	end

	def sorted_certain(query) do
		from p in query,
		where: not is_nil(p.latest_default_results),
		order_by: [desc: p.id]
	end

	def sorted_least_certain(query) do
		from p in query,
		where: not is_nil(p.latest_default_results),
		order_by: [asc: p.id]
	end

	def sorted_for_keyword(query, keyword) do
		case keyword do
			"new" -> query |> Poll.sorted_new
			"top" -> query |> Poll.sorted_top
			"most-certain" -> query |> Poll.sorted_certain
			"least-certain" -> query |> Poll.sorted_least_certain
		end
	end

	defp capitalize_title(title) do
		{a, b} = String.split_at(title, 1)
		(a |> String.upcase) <> b
	end

	def is_custom(poll) do poll.kind == "custom" end

	def get_random() do
		query = from(p in Poll,
		select: p,
		where: p.kind == "custom",
		order_by: fragment("RANDOM()"),
		limit: 1)
		query
		|> Repo.all()
		|> List.first
	end

	def unserialize_results(results) do
		results = for {key, val} <- results, into: %{}, do: {String.to_atom(key), val} 
		if Map.has_key?(results, :by_datetime) do
			by_datetime = results.by_datetime |> Enum.map(fn(datetime_results) ->
				datetime_results = for {key, val} <- datetime_results, into: %{}, do: {String.to_atom(key), val}
				Map.put(datetime_results, :datetime, Timex.to_date({datetime_results.datetime["year"], 1, 1}))
			end)
			Map.put(results, :by_datetime, by_datetime)
		else
			results
		end
	end

	def calculate(poll, calculation_opts) do
		key = {
			{"results", poll.id, calculation_opts.datetime},
			{
				calculation_opts.trust_metric_url,
				calculation_opts.vote_weight_halving_days,
				calculation_opts.minimum_voting_power
			}
		}
		cache_results = ResultsCache.get(key)
		if cache_results do
			cache_results
		else
			vote_weight_halving_days = if poll.kind == "custom" do calculation_opts.vote_weight_halving_days else nil end
			minimum_voting_power = if poll.kind == "custom" do calculation_opts.minimum_voting_power else 0 end

			results = Poll.calculate_contributions(poll, calculation_opts)
			|> AggregateContributions.aggregate(calculation_opts.datetime, vote_weight_halving_days, poll.choice_type, calculation_opts.trust_metric_ids)

			results = if poll.choice_type == "time_quantity" do
				results_with_datetime = results.by_keys
				|> Enum.map(fn({time_key, time_results}) ->
					{year, ""} = Integer.parse(time_key)
					Map.put(time_results, :datetime, Timex.to_date({year, 1, 1}))
				end)
				|> Enum.filter(fn(datetime_result) ->
					datetime_result.total >= minimum_voting_power
				end)
				results |> Map.put(:by_datetime, results_with_datetime)
			else
				main_results = AggregateContributions.by_key(results.by_keys, "main")
				if main_results.total >= minimum_voting_power do
					main_results
				else
					Map.put(main_results, :mean, nil)
				end
			end

			ResultsCache.set(key, results)
		end
	end

	def calculate_contributions(poll, calculation_opts) do
		key = {
			{"contributions", poll.id, calculation_opts.datetime},
			{
				calculation_opts.trust_metric_url,
			}
		}
		cache_results = ResultsCache.get(key)
		if cache_results do
			cache_results
		else
			topics = TopicReference.for_poll(poll, calculation_opts)
			|> Enum.map(& &1.path)
			|> MapSet.new

			votes = GetData.get_votes(poll.id, calculation_opts.datetime)
			inverse_delegations = GetData.get_inverse_delegations(calculation_opts.datetime)

			contributions = CalculateContributions.calculate(votes, inverse_delegations, calculation_opts.trust_metric_ids, topics)

			ResultsCache.set(key, contributions)
		end
	end

	def empty_result() do
		AggregateContributions.empty()
	end

	def results_for_contribution(poll, %{:choice => choice}) do
		if poll.choice_type == "time_quantity" do
			by_datetime = choice
			|> Enum.map(fn({time_key, value}) ->
				{year, ""} = Integer.parse(time_key)
				%{
					:total => 1,
					:turnout_ratio => 1.0,
					:datetime =>  Timex.to_date({year, 1, 1}),
					:mean => value
				}
			end)

			%{
				:total => 1,
				:turnout_ratio => 1.0,
				:by_datetime => by_datetime
			}
		else
			%{
				:total => 1,
				:turnout_ratio => 1.0,
				:mean => choice["main"]
			}
		end
	end

	def invalidate_results_cache(poll) do
		ResultsCache.unset({"results", poll.id})
		ResultsCache.unset({"contributions", poll.id})
		case poll.kind do
			"is_reference" ->
				reference = Repo.get_by(Reference, for_choice_poll_id: poll.id)
				ResultsCache.unset({"references", reference.poll_id})
				ResultsCache.unset({"inverse_references", reference.reference_poll_id})
			"is_topic" ->
				topic = Repo.get_by(TopicReference, relevance_poll_id: poll.id)
				ResultsCache.unset({"topic_polls", topic.path})
				ResultsCache.unset({"topics", topic.poll_id})
			_ -> nil
		end
	end
end
