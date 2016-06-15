defmodule Democracy.Reference do
	use Democracy.Web, :model

	alias Democracy.Repo
	alias Democracy.Poll

	schema "references" do
		belongs_to :poll, Poll
		belongs_to :reference_poll, Poll
		belongs_to :approval_poll, Poll
		field :choice, :string
		field :pole, :string

		timestamps
	end
	
	def changeset(model, params \\ :empty) do
		model
		|> cast(params, ["poll_id", "reference_poll_id", "choice", "pole"], [])
		|> assoc_constraint(:poll)
		|> assoc_constraint(:reference_poll)
		|> validate_inclusion(:pole, ["positive", "negative"])
	end

	def create(changeset) do
		approval_poll = Repo.insert!(%Poll{
			:kind => "is_reference",
			:title => nil,
			:choices => ["true"],
			:topics => nil
		})

		changeset = changeset
		|> put_change(:approval_poll_id, approval_poll.id)
		Repo.insert(changeset)
	end
end
