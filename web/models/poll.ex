defmodule Democracy.Poll do
	use Democracy.Web, :model

	alias Democracy.Repo

	schema "polls" do
		field :kind, :string
		field :title, :string
		field :source_urls, {:array, :string}
		field :choices, {:array, :string}
		field :topics, {:array, :string}

		timestamps
	end
	
	def changeset(model, params \\ :empty) do
		model
		|> cast(params, ["title", "choices"], ["source_urls", "topics"])
		|> put_change(:kind, "custom")
	end

	def create(changeset) do
		# TODO: Store snapshot of source urls content. In case content changes on the url later users can be warned and given the option to view both versions.
		Repo.insert(changeset)
	end
end
