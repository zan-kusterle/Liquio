defmodule Liquio.VoteRepo do
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Repo, Node, NodeRepo, Vote}

	def search(query, search_term) do
		from(v in query,
		where: fragment("? % ?", v.search_text, ^search_term),
		order_by: fragment("similarity(?, ?) DESC", v.search_text, ^search_term))
	end

	def get_at_datetime(path, datetime) do
		query = "SELECT DISTINCT ON (v.identity_id, v.unit, v.at_date) *
			FROM votes AS v
			WHERE v.path = $1 AND v.datetime <= '#{Timex.format!(datetime, "{ISO:Basic}")}'
			ORDER BY v.identity_id, v.unit, v.at_date, v.datetime DESC;"
		res = Ecto.Adapters.SQL.query!(Repo, query , [path])
		cols = Enum.map res.columns, &(String.to_atom(&1))
		votes = res.rows
		|> Enum.map(fn(row) ->
			vote = struct(Liquio.Vote, Enum.zip(cols, row))
			{date, {h, m, s, _}} = vote.datetime
			vote = Map.put(vote, :datetime,  Timex.to_naive_datetime({date, {h, m, s}}))
			vote
		end)
		|> Enum.filter(& &1.choice != nil)
		|> Enum.map(& {{&1.identity_id, &1.unit}, &1}) |> Enum.into(%{}) |> Map.values

		votes
	end

	def current_by(identity, node) do
		from(v in Vote, where:
			v.path == ^node.path and
			v.identity_id == ^identity.id and
			v.is_last
		) |> Repo.all
	end

	def set(identity, node, unit, choice) do
		group_key = Vote.group_key(%{path: node.path, unit: unit})
		
		from(v in Vote,
			where: v.group_key == ^group_key and
				v.identity_id == ^identity.id and
				v.is_last == true,
			update: [set: [is_last: false]])
		|> Repo.update_all([])

		result = Repo.insert!(%Vote{
			:identity_id => identity.id,

			:path => node.path,
			:group_key => group_key,
			:search_text => Enum.join(node.path, " "),

			:unit => Vote.encode_unit(unit),
			:choice => choice,
			
			:is_last => true,
			:at_date => Timex.today()
		})

		NodeRepo.invalidate_cache(node)
		result
	end

	def delete(identity, node, unit) do
		VoteRepo.set(identity, node, unit, nil)
	end
end