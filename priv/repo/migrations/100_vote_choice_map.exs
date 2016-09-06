defmodule Liquio.Repo.Migrations.VoteChoiceMap do
	use Ecto.Migration

	alias Liquio.Repo
	alias Liquio.Vote

	def up do
		Vote |> Repo.all |> Enum.map(fn(vote) ->
			if vote.data != nil do
				choice = vote.data.choice
				if is_number(choice) do
					new_data = Map.put(vote.data, :choice, %{:main => choice})
					Repo.update! Ecto.Changeset.change vote, data: new_data
				end
			end
		end)
	end

	def down do
		Vote |> Repo.all |> Enum.map(fn(vote) ->
			if vote.data != nil do
				choice = vote.data.choice
				if is_map(choice) and Map.has_key?(choice, "main") do
					new_data = Map.put(vote.data, :choice, vote.data.choice["main"])
					Repo.update! Ecto.Changeset.change vote, data: new_data
				end
			end
		end)
	end
end
