defmodule Democracy.Reference do
	use Democracy.Web, :model

	schema "references" do
		belongs_to :poll, Democracy.Poll
		belongs_to :reference_poll, Democracy.Poll
		belongs_to :reference_document, Democracy.Document
		belongs_to :approval_poll, Democracy.Poll
		field :reference_kind, :string
		field :choice, :string
		field :pole, :string

		timestamps
	end
	
	def changeset(model, params \\ :empty) do
		model
		|> cast(params, ["poll_id", "reference_kind", "choice", "pole"], ["reference_poll_id", "reference_document_id"])
		|> assoc_constraint(:poll)
		|> assoc_constraint(:reference_poll)
		|> assoc_constraint(:reference_document)
		|> validate_inclusion(:pole, ["positive", "negative"])
		|> validate_inclusion(:reference_kind, ["poll", "document"])
	end

	def create(changeset) do
		approval_poll = Repo.insert!(%Democracy.Poll{
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
