defmodule Democracy.Delegation do
	use Democracy.Web, :model

	schema "delegations" do
		belongs_to :from_identity, Democracy.Identity
		belongs_to :to_identity, Democracy.Identity

		field :weight, :float
		field :topics, {:array, :string}

		timestamps
	end

	def changeset(model, params \\ :empty) do
		if is_integer(params["weight"]) do
			params = Map.put(params, "weight", params["weight"] * 1.0)
		end
		model
		|> cast(params, ["from_identity_id", "to_identity_id"], ["weight", "topics"])
		|> assoc_constraint(:from_identity)
		|> assoc_constraint(:to_identity)
		|> validate_number(:weight, greater_than_or_equal_to: 0)
		# TODO: Validate cycles
	end
end
