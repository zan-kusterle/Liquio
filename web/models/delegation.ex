defmodule Democracy.Delegation do
	use Democracy.Web, :model

	schema "delegations" do
		belongs_to :from_identity, Democracy.Identity
		belongs_to :to_identity, Democracy.Identity

		field :weight, :float
		field :topics, {:array, :string}

		timestamps
	end

	@required_fields ~w(from_identity_id to_identity_id weight)
	@optional_fields ~w()
	
	def changeset(model, params \\ :empty) do
		model
		|> cast(params, @required_fields, @optional_fields)
	end
end
