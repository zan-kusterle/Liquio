defmodule Liquio.Poll do
	use Liquio.Web, :model

	alias Liquio.Repo
	alias Liquio.Poll
	alias Liquio.Vote
	alias Liquio.Reference
	alias Liquio.Identity

	schema "polls" do
		field :kind, :string
		field :choice_type, :string
		field :choice_derivative, :integer
		field :choice_derivative_unit, :string
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
		|> put_change(:kind, "custom")
		|> put_change(:choice_derivative, 0)
	end

	def create(changeset) do
		Repo.insert(changeset)
	end

	def create(choice_type, title, topics) do
		Repo.insert!(%Poll{
			:kind => "custom",
			:choice_type => choice_type,
			:choice_derivative => 0,
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
		title = title |> String.split(" ") |> Enum.map(fn(word) ->
			cond do
				is_acronymn(word) ->
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
end
