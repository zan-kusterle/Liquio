defmodule Democracy.Poll do
	use Democracy.Web, :model

	alias Democracy.Repo
	alias Democracy.Poll
	alias Democracy.Vote

	schema "polls" do
		field :kind, :string
		field :title, :string
		field :source_urls, {:array, :string}
		field :topics, {:array, :string}

		has_many :votes, Vote

		timestamps
	end
	
	def changeset(data, params) do
		data
		|> cast(params, ["title", "source_urls", "topics"])
		|> validate_required(:title)
		|> put_change(:kind, "custom")
	end

	def create(changeset) do
		# TODO: Store snapshot of source urls content. In case content changes on the url later users can be warned and given the option to view both versions.
		Repo.insert(changeset)
	end

	def create(title, topics) do
		Repo.insert!(%Poll{
			:kind => "custom",
			:title => title,
			:source_urls => [],
			:topics => topics,
		})
	end

	def search(query, search_term) do
		from(p in query,
		where: fragment("? % ?", p.title, ^search_term),
		order_by: fragment("similarity(?, ?) DESC", p.title, ^search_term))
	end

	def all() do
		from(p in Poll, where: p.kind == "custom")
	end

	def by_topic(topic) do
		from(p in Poll, where: p.kind == "custom" and fragment("? = ANY(?)", ^topic, p.topics))
	end

	def get_random() do
		# TODO: More likely to choose popular polls
		from(p in Poll,
		select: p,
		where: p.kind == "custom",
		order_by: fragment("RANDOM()"),
		limit: 1)
		|> Repo.all()
		|> List.first
	end
end
