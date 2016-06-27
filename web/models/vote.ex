defmodule Democracy.VoteData do
	use Democracy.Web, :model

	embedded_schema do
		field :score, :float
	end

	def changeset(data, params) do
		data
		|> cast(params, ["score"])
		|> validate_required(:score)
	end
end

defmodule Democracy.Vote do
	use Democracy.Web, :model

	alias Democracy.Repo
	alias Democracy.Vote
	alias Democracy.VoteData

	schema "votes" do
		belongs_to :poll, Democracy.Poll
		belongs_to :identity, Democracy.Identity

		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :is_last, :boolean

		embeds_one :data, VoteData
	end

	def changeset(data, params) do
		data
		|> cast(params, ["poll_id", "identity_id"])
		|> validate_required(:poll_id)
		|> validate_required(:identity_id)
		|> assoc_constraint(:poll)
		|> assoc_constraint(:identity)
		|> put_embed(:data, VoteData.changeset(%VoteData{}, params))
	end

	def set(changeset) do
		remove_current_last(changeset.params["poll_id"], changeset.params["identity_id"])
		changeset = changeset
		|> put_change(:is_last, true)
		Repo.insert(changeset)
	end

	def delete(poll, identity) do
		remove_current_last(poll.id, identity.id)
		Repo.insert!(%Vote{
			:poll_id => poll.id,
			:identity_id => identity.id,
			:is_last => true,
			:data => nil
		})
	end

	def remove_current_last(poll_id, identity_id) do
		current_last = Repo.get_by(Vote,
			poll_id: poll_id, identity_id: identity_id, is_last: true)
		if current_last do
			Repo.update! Ecto.Changeset.change current_last, is_last: false
		end
	end
end
