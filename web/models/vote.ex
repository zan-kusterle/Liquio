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

	def search(query, search_term) do
		from(v in query,
		where: fragment("? % ?", v.title, ^search_term),
		order_by: fragment("similarity(?, ?) DESC", v.title, ^search_term))
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
		#Map.keys(choice) |> Enum.filter(& String.ends_with?(&1, "?")) |> Enum.map(& String.replace(&1, "?", ""))
		
		#new_choice = if choice_name == "for_choice" do
		#	current_choice = current_choice
		#	|> Map.put("for_choice", choice["main"])
		#	if not Map.has_key?(current_choice, "relevance") do
		#		current_choice = current_choice
		#		|> Map.put("relevance", 1.0)
		#	else
		#		current_choice
		#	end
		#else
		#	current_choice = current_choice
		#	|> Map.put("relevance", choice["main"])
		#end

		current = current_by(node, identity)
		remove_current_last(node.key, identity.id, node.reference_key)
		new_choice = if current != nil and current.data != nil do Map.merge(current.data.choice, choice) else choice end
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
		query = if reference_key == nil do
			from(v in Vote,
			where:
				v.key == ^key and
				v.identity_id == ^identity_id and
				is_nil(v.reference_key) and
				v.is_last == true,
			update: [set: [is_last: false]])
		else
			from(v in Vote,
			where:
				v.key == ^key and
				v.identity_id == ^identity_id and
				v.reference_key == ^reference_key and
				v.is_last == true,
			update: [set: [is_last: false]])
		end
		
		query |> Repo.update_all([])
	end

	def get_last(node, identity) do
		if node.reference_key == nil do
			query = from(v in Vote, where:
				v.key == ^node.key and
				v.identity_id == ^identity.id and
				is_nil(v.reference_key) and
				v.is_last
			)
			Repo.all(query)
		else
			query = from(v in Vote, where:
				v.key == ^node.key and
				v.identity_id == ^identity.id and
				v.reference_key == ^node.reference_key and
				v.is_last
			)
			Repo.all(query)
		end
	end

	defp invalidate_results_cache(node) do
		ResultsCache.unset({"nodes", {node.key, node.reference_key}})
	end
end