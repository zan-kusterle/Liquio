defmodule Liquio.ReferenceVote do
	use Liquio.Web, :model
	alias Liquio.{Repo, ReferenceRepo, ReferenceVote}

	schema "reference_votes" do
		belongs_to :identity, Liquio.Identity

		field :path, {:array, :string}
		field :reference_path, {:array, :string}

		field :relevance, :float
		
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :is_last, :boolean

		field :group_key, :string
	end
	
	def get_at_datetime(path, reference_path, datetime) do
		query = "SELECT DISTINCT ON (v.identity_id) *
			FROM reference_votes AS v
			WHERE lower(v.group_key) = $1 AND v.datetime <= '#{Timex.format!(datetime, "{ISO:Basic}")}'
			ORDER BY v.identity_id, v.datetime DESC;"
		group_key = Reference.group_key(%{:path => path, :reference_path => reference_path})
		res = Ecto.Adapters.SQL.query!(Repo, query , [group_key])
		cols = Enum.map res.columns, &(String.to_atom(&1))
		votes = res.rows
		|> Enum.map(fn(row) ->
			vote = struct(Liquio.Vote, Enum.zip(cols, row))
			{date, {h, m, s, _}} = vote.datetime
			vote = Map.put(vote, :datetime,  Timex.to_naive_datetime({date, {h, m, s}}))
			vote
		end)
		|> Enum.filter(& &1.choice != nil)
		|> Enum.map(& {&1.identity_id, &1}) |> Enum.into(%{}) |> Map.values
		
		votes
	end
	
	def current_by(identity, reference) do
		query = from(v in ReferenceVote, where:
			v.group_key == ^reference.group_key and
			v.identity_id == ^identity.id and
			v.is_last
		)
		votes = Repo.all(query)
		if Enum.empty?(votes) or Enum.at(votes, 0).choice == nil do
			nil
		else
			Enum.at(votes, 0)
		end
	end

	def set(identity, reference, relevance) do
		group_key = Reference.group_key(reference)

		from(v in ReferenceVote,
			where: v.group_key == ^group_key and
				v.identity_id == ^identity.id and
				v.is_last == true,
			update: [set: [is_last: false]]
		) |> Repo.update_all([])

		result = Repo.insert!(%ReferenceVote{
			:identity_id => identity.id,

			:path => reference.path,
			:reference_path => reference.reference_path,
			:relevance => relevance,
			
			:is_last => true,
			:group_key => group_key
		})
		ReferenceRepo.invalidate_cache(reference)
		result
	end

	def delete(identity, reference) do
		ReferenceVote.set(identity, reference, nil)
	end
end