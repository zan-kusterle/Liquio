defmodule Liquio.ReferenceVote do
	use Liquio.Web, :model
	alias Liquio.{Repo, NodeRepo, Vote}
	
	schema "reference_votes" do
		belongs_to :identity, Liquio.Identity

		field :path, {:array, :string}
		field :reference_path, {:array, :string}

		field :relevance, :float
		
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :is_last, :boolean

		field :group_key, :string
	end
	
	def get_reference_votes(path, reference_path, datetime) do
		query = "SELECT DISTINCT ON (v.identity_id) *
			FROM reference_votes AS v
			WHERE lower(v.group_key) = $1 AND v.datetime <= '#{Timex.format!(datetime, "{ISO:Basic}")}'
			ORDER BY v.identity_id, v.datetime DESC;"
		res = Ecto.Adapters.SQL.query!(Repo, query , [String.downcase(group_key)])
		cols = Enum.map res.columns, &(String.to_atom(&1))
		votes = res.rows
		|> Enum.map(fn(row) ->
			vote = struct(Liquio.Vote, Enum.zip(cols, row))
			{date, {h, m, s, _}} = vote.datetime
			vote = Map.put(vote, :datetime,  Timex.to_naive_datetime({date, {h, m, s}}))
			vote
		end)
		|> Enum.filter(& &1.choice != nil)
		|> Enum.map(& {&1.identity_id, &1}) |> Enum.into(%{})

		votes
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
		remove_current_last(node.group_key, identity.id)
		result = insert(node, identity, choice)
		NodeRepo.invalidate_cache(node)
		result
	end

	def delete(node, identity) do
		remove_current_last(node.group_key, identity.id)
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

			:path => node.path,
			:reference_path => node.reference_path,
			:group_key => node.group_key,

			:relevance => relevance,
			
			:is_last => true
		})
	end
end