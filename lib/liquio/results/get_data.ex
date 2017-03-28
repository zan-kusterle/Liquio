defmodule Liquio.GetData do
	alias Liquio.Repo

	def get_inverse_delegations(datetime) do
		query = "SELECT DISTINCT ON (d.from_identity_id, d.to_identity_id) *
			FROM delegations AS d
			WHERE d.datetime <= '#{Timex.format!(datetime, "{ISO:Basic}")}'
			ORDER BY d.from_identity_id, d.to_identity_id, d.datetime DESC;"
		res = Ecto.Adapters.SQL.query!(Repo, query , [])
		cols = Enum.map res.columns, &(String.to_atom(&1))
		inverse_delegations = res.rows
		|> Enum.map(fn(row) ->
			delegation = struct(Liquio.Delegation, Enum.zip(cols, row))
			if delegation.data do
				delegation
				|> Map.put(:weight, delegation.data.weight)
				|> Map.put(:topics, MapSet.new(delegation.data.topics))
			else
				delegation
			end
		end)
		|> Enum.filter(& &1.data != nil)
		|> Enum.map(& {&1.to_identity_id, &1}) |> Enum.into(%{})

		inverse_delegations
	end

	def get_votes(group_key, datetime) do
		query = "SELECT DISTINCT ON (v.identity_id) *
			FROM votes AS v
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
end