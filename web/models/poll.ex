defmodule Democracy.Poll do
	use Democracy.Web, :model

	schema "polls" do
		field :kind, :string
		field :title, :string
		field :choices, {:array, :string}
		field :topics, {:array, :string}

		timestamps
	end
	
	def changeset(model, params \\ :empty) do
		model
		|> cast(params, ["title", "choices"], ["topics"])
		|> put_change(:kind, "custom")
	end
end
