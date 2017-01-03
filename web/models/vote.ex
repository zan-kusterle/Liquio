defmodule Liquio.VoteData do
	use Liquio.Web, :model

	embedded_schema do
		field :choice, {:map, :float}
	end

	def changeset(data, params) do
		data
		|> cast(params, ["choice"])
		|> validate_required(:choice)
	end
end

defmodule Liquio.Vote do
	@moduledoc """
	Describes vote schema and provides functions for finding, adding and removing votes.
	"""

	use Liquio.Web, :model

	alias Liquio.Repo
	alias Liquio.Vote
	alias Liquio.VoteData
	alias Liquio.Reference
	alias Liquio.TopicReference
	alias Liquio.ResultsCache

	schema "votes" do
		belongs_to :poll, Liquio.Poll
		belongs_to :identity, Liquio.Identity

		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :is_last, :boolean

		embeds_one :data, VoteData
	end

	def current_by(poll, identity) do
		vote = Repo.get_by(Vote, identity_id: identity.id, poll_id: poll.id, is_last: true)
		if vote != nil and vote.data != nil do
			vote
		else
			nil
		end
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
		result = Repo.insert(changeset)
		invalidate_results_cache(Repo.get!(Poll, changeset.params["poll_id"]))
		result
	end
	def set(poll, identity, choice) do
		remove_current_last(poll.id, identity.id)
		result = Repo.insert(%Vote{
			:poll_id => poll.id,
			:identity_id => identity.id,
			:is_last => true,
			:data => %VoteData{
				:choice => choice
			}
		})
		invalidate_results_cache(poll)
		result
	end

	def delete(poll, identity) do
		remove_current_last(poll.id, identity.id)
		result = Repo.insert!(%Vote{
			:poll_id => poll.id,
			:identity_id => identity.id,
			:is_last => true,
			:data => nil
		})
		invalidate_results_cache(poll)
		result
	end

	defp invalidate_results_cache(poll) do
		ResultsCache.unset({"results", poll.id})
		ResultsCache.unset({"contributions", poll.id})
		case poll.kind do
			"is_reference" ->
				reference = Repo.get_by(Reference, for_choice_poll_id: poll.id)
				ResultsCache.unset({"references", reference.poll_id})
				ResultsCache.unset({"inverse_references", reference.reference_poll_id})
			"is_topic" ->
				topic = Repo.get_by(TopicReference, relevance_poll_id: poll.id)
				ResultsCache.unset({"topic_polls", topic.path})
				ResultsCache.unset({"topics", topic.poll_id})
			_ -> nil
		end
	end

	defp remove_current_last(poll_id, identity_id) do
		current_last = Repo.get_by(Vote,
			poll_id: poll_id, identity_id: identity_id, is_last: true)
		if current_last do
			Repo.update! Ecto.Changeset.change current_last, is_last: false
		end
	end
end
