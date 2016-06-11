defmodule Democracy.Poll do
	use Democracy.Web, :model

	schema "polls" do
		field :kind, :string
		field :title, :string
		field :choices, {:array, :string}
		field :topics, {:array, :string}
		field :is_direct, :boolean

		timestamps
	end
	
	def changeset(model, params \\ :empty) do
		model
		|> cast(params, ["title", "choices"], ["topics"])
		|> put_change(:kind, "custom")
		|> put_change(:is_direct, false)
	end
end
