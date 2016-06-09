defmodule Democracy.Poll do
	use Democracy.Web, :model

	schema "polls" do
		field :title, :string
		field :choices, {:array, :string}
		field :topics, {:array, :string}
		field :is_direct, :boolean

		timestamps
	end

	@required_fields ~w(title choices)
	@optional_fields ~w(topics is_direct)
	
	def changeset(model, params \\ :empty) do
		model
		|> cast(params, @required_fields, @optional_fields)
	end

	def new(params) do
		changeset(%Democracy.Poll{}, params)
	end
end
