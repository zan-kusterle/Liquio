defmodule Liquio.VoteRepo do
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Repo, Node, NodeRepo, Vote}

	def search(query, search_term) do
		from(v in query,
		where: fragment("? % ?", v.search_text, ^search_term),
		order_by: fragment("similarity(?, ?) DESC", v.search_text, ^search_term))
	end

	def get_at_datetime(path, datetime) do
		{path_where, path_params} = if path do
			q = path |> Enum.with_index |> Enum.map(fn({value, index}) ->
				"lower(v.path[#{index + 1}]) = $#{index + 1}"
			end) |> Enum.join(" AND ")
			{"#{q} AND", Enum.map(path, & String.downcase(&1))}
		else
			{"", []}
		end

		query = "SELECT *
			FROM votes AS v
			WHERE #{path_where}
				v.datetime <= '#{Timex.format!(datetime, "{ISO:Basic}")}' AND
				(v.to_datetime IS NULL OR v.to_datetime >='#{Timex.format!(datetime, "{ISO:Basic}")})')
			ORDER BY v.datetime;"
		res = Ecto.Adapters.SQL.query!(Repo, query, path_params)
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
			is_nil(v.to_datetime) and
			not is_nil(v.choice)
		) |> Repo.all
	end

	def set(identity, node, unit, at_date, choice) do
		group_key = Vote.group_key(%{path: node.path, unit: unit, at_date: at_date})
		
		now = Timex.now
		from(v in Vote,
			where: v.group_key == ^group_key and
				v.identity_id == ^identity.id and
				is_nil(v.to_datetime),
			update: [set: [to_datetime: ^now]])
		|> Repo.update_all([])

		result = Repo.insert!(%Vote{
			:identity_id => identity.id,

			:path => node.path,
			:group_key => group_key,
			:search_text => Enum.join(node.path, " "),

			:unit => Vote.encode_unit(unit),
			:choice => choice,
			
			:to_datetime => nil,
			:at_date => at_date
		})

		NodeRepo.invalidate_cache(node)
		result
	end

	def delete(identity, node, unit, at_date) do
		set(identity, node, unit, at_date, nil)
	end
end