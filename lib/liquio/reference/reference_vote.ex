defmodule Liquio.ReferenceVote do
	use Liquio.Web, :model
	alias Liquio.{Repo, Vote, Reference, ReferenceRepo, ReferenceVote}

	schema "reference_votes" do
		belongs_to :identity, Liquio.Identity

		field :path, {:array, :string}
		field :reference_path, {:array, :string}

		field :relevance, :float
		
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :to_datetime, Timex.Ecto.DateTime

		field :group_key, :string
	end
	
	def get_at_datetime(path, reference_path, datetime) do
		{path_where, path_params} = if path do
			q = path |> Enum.with_index |> Enum.map(fn({value, index}) ->
				"v.path[#{index + 1}] = $#{index + 1}"
			end) |> Enum.join(" AND ")
			{q, path}
		else
			{nil, []}
		end

		{reference_path_where, reference_path_params} = if reference_path do
			q = reference_path |> Enum.with_index |> Enum.map(fn({value, index}) ->
				"v.reference_path[#{index + 1}] = $#{index + 1 + Enum.count(path_params)}"
			end) |> Enum.join(" AND ")
			{q, reference_path}
		else
			{nil, []}
		end

		paths_where = cond do
			path != nil and reference_path != nil -> "(#{path_where}) AND (#{reference_path_where}) AND"
			path != nil -> "(#{path_where}) AND"
			reference_path != nil -> "(#{reference_path_where}) AND"
			true -> ""
		end

		query = "SELECT *
			FROM reference_votes AS v
			WHERE #{paths_where} v.datetime <= '#{Timex.format!(datetime, "{ISO:Basic}")}'
				AND (v.to_datetime IS NULL) OR v.to_datetime >= '#{Timex.format!(datetime, "{ISO:Basic}")}'
			ORDER BY v.identity_id, v.datetime DESC;"
		
		res = Ecto.Adapters.SQL.query!(Repo, query , path_params ++ reference_path_params)
		cols = Enum.map res.columns, &(String.to_atom(&1))
		votes = res.rows
		|> Enum.map(fn(row) ->
			vote = struct(ReferenceVote, Enum.zip(cols, row))
			{date, {h, m, s, _}} = vote.datetime
			vote = vote
			|> Map.put(:datetime,  Timex.to_naive_datetime({date, {h, m, s}}))
		end)
		|> Enum.filter(& &1.relevance != nil)

		votes
	end
	
	def current_by(identity, reference) do
		query = from(v in ReferenceVote, where:
			v.path == ^reference.path and v.reference_path == ^reference.reference_path and
			v.identity_id == ^identity.id and
			is_nil(v.to_datetime) and
			not is_nil(v.relevance)
		)
		votes = Repo.all(query)
		if Enum.empty?(votes) or Enum.at(votes, 0).relevance == nil do
			nil
		else
			Enum.at(votes, 0)
		end
	end

	def set(identity, reference, relevance) do
		group_key = Reference.group_key(reference)

		now = Timex.now
		from(v in ReferenceVote,
			where: v.group_key == ^group_key and
				v.identity_id == ^identity.id and
				is_nil(v.to_datetime),
			update: [set: [to_datetime: ^now]]
		) |> Repo.update_all([])

		result = Repo.insert!(%ReferenceVote{
			:identity_id => identity.id,

			:path => reference.path,
			:reference_path => reference.reference_path,
			:relevance => relevance,
			
			:to_datetime => nil,
			:group_key => group_key
		})
		ReferenceRepo.invalidate_cache(reference)
		result
	end

	def delete(identity, reference) do
		ReferenceVote.set(identity, reference, nil)
	end
end