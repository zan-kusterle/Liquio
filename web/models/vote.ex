defmodule Democracy.Vote do
	use Democracy.Web, :model

	schema "votes" do
		belongs_to :poll, Democracy.Poll
		belongs_to :identity, Democracy.Identity
		field :choice, :string
		field :score, :float

		timestamps
	end

	@required_fields ~w(poll_id identity_id choice score)
	@optional_fields ~w()
	
	def changeset(model, params \\ :empty) do
		model
		|> cast(params, @required_fields, @optional_fields)
	end

	def new(identity, poll, choice, score) do
		changeset(%Democracy.Vote{
			:identity_id => identity.id,
			:poll_id => poll.id,
			:choice => choice,
			:score => score
		}, %{})
	end
end
