defmodule Liquio.VoteRepo do
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Repo, Node, NodeRepo, Vote}

	def search(query, search_term) do
		from(v in query,
		where: fragment("? % ?", v.search_text, ^search_term),
		order_by: fragment("similarity(?, ?) DESC", v.search_text, ^search_term))
	end

	def get_at_datetime(path, datetime) do
		query = "SELECT *
			FROM votes AS v
			WHERE v.path = $1 AND v.datetime <= '#{Timex.format!(datetime, "{ISO:Basic}")}'
			ORDER BY v.datetime;"
		res = Ecto.Adapters.SQL.query!(Repo, query , [path])
		cols = Enum.map res.columns, &(String.to_atom(&1))
		votes = res.rows
		|> Enum.map(fn(row) ->
			vote = struct(Liquio.Vote, Enum.zip(cols, row))
			{date, {h, m, s, _}} = vote.datetime
			vote = Map.put(vote, :datetime, Timex.to_naive_datetime({date, {h, m, s}}))
			vote = Map.put(vote, :at_date, Timex.to_date(vote.at_date))
			vote
		end)
		|> Enum.filter(& &1.choice != nil)

		votes
	end

	def current_by(identity, node) do
		from(v in Vote, where:
			v.path == ^node.path and
			v.identity_id == ^identity.id and
			v.is_last and
			not is_nil(v.choice)
		) |> Repo.all
	end

	def set(identity, node, unit, at_date, choice) do
		group_key = Vote.group_key(%{path: node.path, unit: unit, at_date: at_date})
		
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
			:at_date => at_date
		})

		NodeRepo.invalidate_cache(node)
		result
	end

	def delete(identity, node, unit, at_date) do
		set(identity, node, unit, at_date, nil)
	end
end