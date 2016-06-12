defmodule Democracy.VoteData do
	use Ecto.Model

	embedded_schema do
		field :score_by_choices, :map
	end

	def changeset(model, params \\ :empty) do
		model
		|> cast(params, ["score_by_choices"], [])
		|> validate_number(:score, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
	end
end

defmodule Democracy.Vote do
	use Democracy.Web, :model

	alias Democracy.VoteData

	schema "votes" do
		belongs_to :poll, Democracy.Poll
		belongs_to :identity, Democracy.Identity

		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :is_last, :boolean

		embeds_one :data, VoteData
	end

	def changeset(model, params \\ :empty) do
		if is_integer(params["score"]) do
			params = Map.put(params, "score", params["score"] * 1.0)
		end

		model
		|> cast(params, ["poll_id", "identity_id"], [])
		|> assoc_constraint(:poll)
		|> assoc_constraint(:identity)
		|> put_change(:data, VoteData.changeset(%VoteData{}, params))
	end
end
