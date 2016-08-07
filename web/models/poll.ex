defmodule Democracy.Poll do
	use Democracy.Web, :model

	alias Democracy.Repo
	alias Democracy.Poll
	alias Democracy.Vote
	alias Democracy.Reference
	alias Democracy.Identity

	schema "polls" do
		field :kind, :string
		field :choice_type, :string
		field :title, :string
		field :topics, {:array, :string}

		has_many :votes, Vote

		timestamps
	end
	
	def changeset(data, params) do
		if Map.has_key?(params, "title") and is_bitstring(params["title"]) do
			params = Map.put(params, "title", capitalize_title(params["title"]))
		end
		data
		|> cast(params, ["choice_type", "title", "topics"])
		|> validate_required(:title)
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
		title |> String.split(" ") |> Enum.map(fn(word) ->
			cond do
				is_acronymn(word) ->
					word
				String.downcase(word) in ["a", "an", "the", "at", "by", "for", "in", "of", "on", "to", "up", "and", "as", "but", "or", "nor"] ->
					String.downcase(word)
				true ->
					String.capitalize(word)
			end
		end) |> Enum.join(" ")
	end

	defp is_acronymn(w) do
		w == String.upcase(w) and String.length(w) >= 2
	end

	def is_custom(poll) do poll.kind == "custom" end

	def get_random() do
		from(p in Poll,
		select: p,
		where: p.kind == "custom",
		order_by: fragment("RANDOM()"),
		limit: 1)
		|> Repo.all()
		|> List.first
	end
end
