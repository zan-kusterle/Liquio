defmodule Liquio.VoteData do
	use Liquio.Web, :model

	embedded_schema do
		field :choice, {:map, :float}
	end
end

defmodule Liquio.Vote do
	use Liquio.Web, :model

	alias Liquio.Repo
	alias Liquio.Node
	alias Liquio.Vote
	alias Liquio.VoteData
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

	def choice(vote) do

	end

	def current_by(node, identity) do
		votes = get_last(node, identity)
		if Enum.empty?(votes) or Enum.at(votes, 0).data == nil do
			nil
		else
			Enum.at(votes, 0)
		end
	end

	def set(node, identity, choice) do
		current = get_and_remove_current_last(node.key, identity.id, node.reference_key)
		current_choice = if current != nil and current.data != nil do current.data.choice else %{} end
		new_choice = Map.merge(current_choice, choice)
		new_choice = if Enum.count(new_choice) == 0 do nil else new_choice end
		result = Repo.insert(%Vote{
			:title => node.title,
			:choice_type => node.choice_type,
			:key => node.key,
			:reference_key => node.reference_key,
			:identity_id => identity.id,
			:is_last => true,
			:data => %VoteData{
				:choice => new_choice
			}
		})
		invalidate_results_cache(node)
		result
	end

	def delete(node, identity) do
		get_and_remove_current_last(node.key, identity.id, node.reference_key)
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

	defp get_and_remove_current_last(key, identity_id, reference_key) do
		current_last = get_last(Node.for_reference_key(Node.from_key(key), reference_key), %{:id => identity_id})
		Enum.each(current_last,fn(vote) ->
			Repo.update! Ecto.Changeset.change vote, is_last: false
		end)
		current_last |> Enum.at(0)
	end

	def get_last(node, identity) do
		if node.reference_key == nil do
			query = from(v in Vote, where:
				v.key == ^node.key and
				v.identity_id == ^identity.id and
				is_nil(v.reference_key) and
				v.is_last == true
			)
			Repo.all(query)
		else
			query = from(v in Vote, where:
				v.key == ^node.key and
				v.identity_id == ^identity.id and
				v.reference_key == ^node.reference_key and
				v.is_last == true
			)
			Repo.all(query)
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