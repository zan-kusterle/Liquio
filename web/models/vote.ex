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
	alias Liquio.Node
	alias Liquio.Vote
	alias Liquio.VoteData
	alias Liquio.Reference
	alias Liquio.TopicReference
	alias Liquio.ResultsCache

	schema "votes" do
		belongs_to :identity, Liquio.Identity

		field :title, :string
		field :choice_type, :string
		field :key, :string

		field :reference_key, :string

		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :is_last, :boolean

		embeds_one :data, VoteData
	end

	def current_by(node, identity) do
		vote = if node.reference_key == nil do
			from(v in Vote, where: v.key == ^node.key and v.identity_id == ^identity.id and is_nil(v.reference_key) and v.is_last == true) |> Repo.one
		else
			Repo.get_by(Vote, key: node.key, identity_id: identity.id, reference_key: node.reference_key, is_last: true)
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
		invalidate_results_cache(Node.new(changeset.params["key"], changeset.params["key"]))
		result
	end
	def set(node, identity, choice) do
		remove_current_last(node.key, identity.id, node.reference_key)
		result = Repo.insert(%Vote{
			:title => node.title,
			:choice_type => node.choice_type,
			:key => node.key,
			:reference_key => node.reference_key,
			:identity_id => identity.id,
			:is_last => true,
			:data => %VoteData{
				:choice => choice
			}
		})
		invalidate_results_cache(node)
		result
	end

	def delete(node, identity) do
		remove_current_last(node.key, identity.id, node.reference_key)
		result = Repo.insert!(%Vote{
			:title => node.title,
			:choice_type => node.choice_type,
			:key => node.key,
			:reference_key=> node.reference_key,
			:identity_id => identity.id,
			:is_last => true,
			:data => nil
		})
		invalidate_results_cache(node)
		result
	end

	defp remove_current_last(key, identity_id, reference_key) do
		current_last = Vote.current_by(Node.for_reference_key(Node.from_key(key), reference_key), %{:id => identity_id})
		if current_last do
			Repo.update! Ecto.Changeset.change current_last, is_last: false
		end
	end

	defp invalidate_results_cache(node) do
		ResultsCache.unset({"contributions", {node.key, node.reference_key}})
		if node.reference_key != nil do
			ResultsCache.unset({"references", node.key})
			ResultsCache.unset({"inverse_references", node.reference_key})
		end
	end
end