defmodule Liquio.Poll do
	use Liquio.Web, :model

	alias Liquio.Repo
	alias Liquio.Poll
	alias Liquio.Vote
	alias Liquio.Reference
	alias Liquio.Identity
	alias Liquio.Results.GetData
	alias Liquio.Results.CalculateContributions
	alias Liquio.Results.AggregateContributions

	schema "polls" do
		field :kind, :string
		field :choice_type, :string
		field :title, :string
		field :topics, {:array, :string}

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
		|> cast(params, ["choice_type", "title", "topics"])
		|> validate_required(:title)
		|> validate_required(:choice_type)
		|> validate_required(:topics)
		|> put_change(:kind, "custom")
	end

	def create(changeset) do
		Repo.insert(changeset)
	end

	def create(choice_type, title, topics) do
		Repo.insert!(%Poll{
			:kind => "custom",
			:choice_type => choice_type,
			:title => capitalize_title(title),
			:topics => topics,
		})
	end

	def force_get(choice_type, title, topics) do
		query = from(p in Poll, where:
			p.kind == "custom" and
			p.choice_type == ^choice_type and
			p.title == ^capitalize_title(title) and
			p.topics == ^topics
		)
		poll = query
		|> Ecto.Query.first
		|> Repo.one
		if poll == nil do
			Poll.create(choice_type, title, topics)
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

	def by_topic(topic) do
		from(p in Poll, where: p.kind == "custom" and fragment("? = ANY(?)", ^topic, p.topics))
	end

	defp capitalize_title(title) do
		words = title |> String.split(" ")
		title = Enum.zip([nil] ++ words, words) |> Enum.map(fn({previous_word, word}) ->
			previous_word = if previous_word == nil do nil else String.downcase(previous_word) end
			cond do
				is_acronymn(word) or is_unit(previous_word, word) ->
					word
				String.downcase(word) in ["a", "an", "the", "at", "by", "for", "in", "of", "on", "to", "up", "and", "as", "but", "or", "nor"] ->
					String.downcase(word)
				true ->
					String.capitalize(word)
			end
		end) |> Enum.join(" ")
		{a, b} = String.split_at(title, 1)
		(a |> String.upcase) <> b
	end

	defp is_acronymn(w) do
		w == String.upcase(w) and String.length(w) >= 2
	end

	def is_unit(previous_word, w) do
		previous_word == "in" and String.length(w) <= 3
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

	def calculate(poll, calculation_opts) do
		soft_quorum_t = if poll.kind == "custom" do 0 else calculation_opts.soft_quorum_t end

		results = Poll.calculate_contributions(poll, calculation_opts)
		|> AggregateContributions.aggregate(calculation_opts.datetime, calculation_opts.vote_weight_halving_days, soft_quorum_t, poll.choice_type, calculation_opts.trust_metric_ids)

		if poll.choice_type == "time_quantity" do
			results_with_datetime = Enum.map(results.by_keys, fn({time_key, time_results}) ->
				{year, ""} = Integer.parse(time_key)
				%{
					:datetime => Timex.to_date({year, 1, 1}),
					:results => time_results
				}
			end)
			results |> Map.put(:by_datetime, results_with_datetime)
		else
			AggregateContributions.by_key(results.by_keys, "main")
		end
	end

	def calculate_contributions(poll, calculation_opts) do
		topics = if poll.topics == nil do nil else MapSet.new(poll.topics) end

		votes = GetData.get_votes(poll.id, calculation_opts.datetime)
		inverse_delegations = GetData.get_inverse_delegations(calculation_opts.datetime)

		CalculateContributions.calculate(votes, inverse_delegations, calculation_opts.trust_metric_ids, topics)
	end

	def empty_result() do
		AggregateContributions.empty()
	end
end
