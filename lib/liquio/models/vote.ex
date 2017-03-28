defmodule Liquio.Vote do
	use Liquio.Web, :model
	alias Liquio.{Repo, NodeRepo, Vote}

	schema "votes" do
		belongs_to :identity, Liquio.Identity

		field :path, {:array, :string}
		field :reference_path, {:array, :string}
		field :filter_key, :string
		field :group_key, :string
		field :search_text, :string

		field :choice_type, :string
		field :choice, :float
		
		field :at_date, Timex.Ecto.Date
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :is_last, :boolean
	end

	def search(query, search_term) do
		from(v in query,
		where: fragment("? % ?", v.search_text, ^search_term),
		order_by: fragment("similarity(?, ?) DESC", v.search_text, ^search_term))
	end

	def current_by(node, identity) do
		votes = get_last(node, identity)
		if Enum.empty?(votes) or Enum.at(votes, 0).choice == nil do
			nil
		else
			Enum.at(votes, 0)
		end
	end

	def set(node, identity, choice) do
		remove_current_last(node.key, identity.id)
		result = insert(node, identity, choice)
		NodeRepo.invalidate_cache(node)
		result
	end

	def delete(node, identity) do
		remove_current_last(node.key, identity.id)
		result = insert(node, identity, nil)
		NodeRepo.invalidate_cache(node)
		result
	end

	defp remove_current_last(group_key, identity_id) do
		from(v in Vote,
			where: v.group_key == ^group_key and
				v.identity_id == ^identity_id and
				v.is_last == true,
			update: [set: [is_last: false]])
		|> Repo.update_all([])
	end

	defp get_last(node, identity) do
		query = from(v in Vote, where:
			v.group_key == ^node.group_key and
			v.identity_id == ^identity.id and
			v.is_last
		)
		Repo.all(query)
	end

	defp insert(node, identity, choice) do
		Repo.insert!(%Vote{
			:identity_id => identity.id,

			:path => [node.title],
			:reference_path => [node.reference_title],
			:filter_key => "main",
			:group_key => node.group_key,

			:choice_type => to_string(node.choice_type),
			:choice => choice,
			
			:is_last => true,
			:at_date => Timex.today()
		})
	end
end