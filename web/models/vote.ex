defmodule Liquio.VoteData do
	use Liquio.Web, :model

	embedded_schema do
		field :score, :float
	end

	def changeset(data, params) do
		data
		|> cast(params, ["score"])
		|> validate_required(:score)
	end
end

defmodule Liquio.Vote do
	use Liquio.Web, :model

	alias Liquio.Repo
	alias Liquio.Vote
	alias Liquio.VoteData

	schema "votes" do
		belongs_to :poll, Liquio.Poll
		belongs_to :identity, Liquio.Identity

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

	def set(poll, identity, score) do
		remove_current_last(poll.id, identity.id)
		Repo.insert(%Vote{
			:poll_id => poll.id,
			:identity_id => identity.id,
			:is_last => true,
			:data => %VoteData{
				:score => score
			}
		})
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

	def current_by(poll, identity) do
		vote = Repo.get_by(Vote, identity_id: identity.id, poll_id: poll.id, is_last: true)
        if vote != nil and vote.data != nil do
        	vote
        else
        	nil
        end
	end
end
