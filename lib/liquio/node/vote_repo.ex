defmodule Liquio.VoteRepo do
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Repo, Vote, Signature}

	def search(query, search_term) do
		from(v in query,
		where: fragment("? % ?", v.search_text, ^search_term),
		order_by: fragment("similarity(?, ?) DESC", v.search_text, ^search_term))
	end

	def get_at_datetime(path, datetime) do
		{path_where, path_params} = if path do
			q = path |> Enum.with_index |> Enum.map(fn({_value, index}) ->
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

	def current_by(username, node) do
		from(v in Vote, where:
			v.path == ^node.path and
			v.username == ^username and
			is_nil(v.to_datetime)
		) |> Repo.all
	end

	def set(node, public_key, signature, unit, at_date, choice) do
		group_key = Vote.group_key(%{path: node.path, unit: unit, at_date: at_date})

		username = :crypto.hash(:sha512, public_key) |> :binary.bin_to_list
		|> Enum.map(& <<rem(&1, 26) + 97>>)
		|> Enum.slice(0, 16) |> Enum.join("")
		message = "#{username} #{Enum.join(node.path, "/")} #{unit.value} #{:erlang.float_to_binary(choice, decimals: 5)}"

		signature = Signature.add!(public_key, message, signature)

		now = Timex.now
		from(v in Vote,
			where: v.group_key == ^group_key and
				v.username == ^username and
				is_nil(v.to_datetime),
			update: [set: [to_datetime: ^now]])
		|> Repo.update_all([])
		
		result = Repo.insert!(%Vote{
			:signature_id => signature.id,

			:username => username,

			:path => node.path,
			:group_key => group_key,
			:search_text => Enum.join(node.path, " "),

			:unit => Vote.encode_unit(unit),
			:choice => choice,
			
			:to_datetime => nil,
			:at_date => at_date
		})

		result
	end

	def delete(node, public_key, signature, unit, at_date) do
		group_key = Vote.group_key(%{path: node.path, unit: unit, at_date: at_date})

		username = :crypto.hash(:sha512, public_key) |> :binary.bin_to_list
		|> Enum.map(& <<rem(&1, 26) + 97>>)
		|> Enum.slice(0, 16) |> Enum.join("")
		message = "#{username} #{Enum.join(node.path, "/")} #{unit.value}"

		signature = Signature.add!(public_key, message, signature)
		
		now = Timex.now
		from(v in Vote,
			where: v.group_key == ^group_key and
				v.username == ^username and
				is_nil(v.to_datetime),
			update: [set: [to_datetime: ^now]])
		|> Repo.update_all([])
	end
end