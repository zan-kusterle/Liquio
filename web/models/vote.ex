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
	alias Liquio.Poll
	alias Liquio.Node
	alias Liquio.Vote
	alias Liquio.VoteData
	alias Liquio.Reference
	alias Liquio.TopicReference
	alias Liquio.ResultsCache

	schema "votes" do
		belongs_to :poll, Liquio.Poll
		belongs_to :identity, Liquio.Identity

		field :title, :string
		field :choice_type, :string
		field :key, :string

		field :reference_key, :string

		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :is_last, :boolean

		embeds_one :data, VoteData
	end

	def current_by(node, identity) do current_by(node, identity, nil) end
	def current_by(node, identity, reference_node) do
		vote = if reference_node == nil do
			from(v in Vote, where: v.key == ^node.key and v.identity_id == ^identity.id and is_nil(v.reference_key) and v.is_last == true) |> Repo.one
		else
			Repo.get_by(Vote, key: node.key, identity_id: identity.id, reference_key: reference_node.key, is_last: true)
		end
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
		remove_current_last(changeset.params["poll_id"], changeset.params["identity_id"], nil)
		changeset = changeset
		|> put_change(:is_last, true)
		result = Repo.insert(changeset)
		Poll.invalidate_results_cache(Repo.get!(Poll, changeset.params["poll_id"]))
		result
	end
	def set(node, identity, choice) do set(node, identity, choice, nil) end
	def set(node, identity, choice, reference_node) do
		reference_key = reference_node && reference_node.key
		remove_current_last(node.key, identity.id, reference_key)
		result = Repo.insert(%Vote{
			:title => node.title,
			:choice_type => node.choice_type,
			:key => node.key,
			:reference_key => reference_key,
			:identity_id => identity.id,
			:is_last => true,
			:data => %VoteData{
				:choice => choice
			}
		})
		case result do
			{:ok, vote} -> invalidate_results_cache(node, vote)
			true -> nil
		end
		result
	end

	def delete(node, identity) do delete(node, identity, nil) end
	def delete(node, identity, reference_node) do
		reference_key = reference_node && reference_node.key
		remove_current_last(node.key, identity.id, reference_key)
		result = Repo.insert!(%Vote{
			:title => node.title,
			:choice_type => node.choice_type,
			:key => node.key,
			:reference_key=> reference_key,
			:identity_id => identity.id,
			:is_last => true,
			:data => nil
		})
		invalidate_results_cache(node, result)
		result
	end

	defp remove_current_last(key, identity_id, reference_key) do
		current_last = Vote.current_by(Node.from_key(key), %{:id => identity_id}, Node.from_key(reference_key))
		if current_last do
			Repo.update! Ecto.Changeset.change current_last, is_last: false
		end
	end

	defp invalidate_results_cache(node, vote) do
		ResultsCache.unset({"results", node.key})
		ResultsCache.unset({"contributions", node.key})
		if vote.reference_key != nil do
			ResultsCache.unset({"references", node.key})
			ResultsCache.unset({"inverse_references", vote.reference_key})
		end
	end
end