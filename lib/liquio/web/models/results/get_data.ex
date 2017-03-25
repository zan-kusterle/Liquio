defmodule Liquio.Results.GetData do
	alias Liquio.Repo

	def get_inverse_delegations(datetime) do
		query = "SELECT DISTINCT ON (from_identity_id, to_identity_id) from_identity_id, to_identity_id, data
			FROM delegations
			WHERE datetime <= '#{Timex.format!(datetime, "{ISO:Basic}")}'
			ORDER BY from_identity_id, to_identity_id, datetime DESC;"
		rows = Ecto.Adapters.SQL.query!(Repo, query , []).rows
		rows = rows |> Enum.filter(& Enum.at(&1, 2))
		inverse_delegations = for {to_identity_id, to_identity_rows} <- Enum.group_by(rows, &(Enum.at(&1, 1))), into: %{}, do: {
			to_identity_id,
			to_identity_rows |> Enum.map(fn(row) ->
				{
					Enum.at(row, 0),
					Enum.at(row, 2)["weight"],
					if Enum.at(row, 2)["topics"] == nil do nil else MapSet.new(Enum.at(row, 2)["topics"]) end
				}
			end)
		}
		inverse_delegations
	end

	def get_votes(key, reference_key, datetime) do
		key = String.downcase(key)
		query = "SELECT DISTINCT ON (v.identity_id) v.identity_id, v.datetime, v.data, v.title, v.choice_type, v.reference_key
			FROM votes AS v
			WHERE lower(v.key) = $1 AND v.reference_key #{if reference_key do "= $2" else "IS NULL" end} AND v.datetime <= '#{Timex.format!(datetime, "{ISO:Basic}")}'
			ORDER BY v.identity_id, v.datetime DESC;"
		rows = Ecto.Adapters.SQL.query!(Repo, query , if reference_key do [key, reference_key] else [key] end).rows |> Enum.filter(& Enum.at(&1, 2))
		votes = for row <- rows, into: %{} do
			{date, {h, m, s, _}} = Enum.at(row, 1)
			data = %{
				:datetime => Timex.to_naive_datetime({date, {h, m, s}}),
				:choice => Enum.at(row, 2)["choice"],
				:title => Enum.at(row, 3),
				:choice_type => Enum.at(row, 4),
				:key => key,
				:reference_key => Enum.at(row, 5)
			}
			{Enum.at(row, 0), data}
		end
		votes
	end

	def prepare_votes(votes) do
		for vote <- votes, into: %{} do
			{vote.identity_id, prepare_vote(vote)}
		end
	end
	
	def prepare_vote(vote) do
		%{:datetime => vote.datetime, :choice => vote.data.choice, :choice_type => vote.choice_type, :title => vote.title}
	end

	def create_random(filename, num_identities, num_votes, num_delegations_per_identity) do
		trust_identity_ids = Enum.to_list 1..num_identities
		votes = get_random_votes trust_identity_ids, num_votes
		inverse_delegations = get_random_inverse_delegations trust_identity_ids, num_delegations_per_identity

		{:ok, file} = File.open filename, [:write]
		IO.binwrite file, :erlang.term_to_binary({trust_identity_ids |> MapSet.new, votes, inverse_delegations})
	end

	def get_random_inverse_delegations(identity_ids, num_delegations) do
		for to_identity_id <- identity_ids, into: %{}, do: {to_identity_id,
			identity_ids
			|> Enum.slice(max(0, to_identity_id - num_delegations - 1), min(to_identity_id - 1, num_delegations))
			|> Enum.map(& {&1, 1, nil})
		}
	end

	def get_random_votes(identity_ids, num_votes) do
		for identity_id <- identity_ids |> Enum.take_random(num_votes), into: %{}, do: {
			identity_id,
			{
				Timex.now,
				:rand.uniform
			}
		}
	end
end