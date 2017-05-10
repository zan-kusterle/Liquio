defmodule Liquio.Repo.Migrations.CreateVote do
	use Ecto.Migration

	def change do
		create table(:reference_votes) do
			add :identity_id, references(:identities, on_delete: :nothing), null: false

			add :path, {:array, :string}, null: false
			add :reference_path, {:array, :string}, null: false
			add :group_key, :string, null: false

			add :relevance, :float, null: false

			add :datetime, :utc_datetime, null: false
			add :to_datetime, :utc_datetime, null: true
		end

		create index(:reference_votes, [:identity_id])
		create index(:reference_votes, [:path])
		create index(:reference_votes, [:reference_path])
		create index(:reference_votes, [:group_key])
		create index(:reference_votes, [:datetime])
		create index(:reference_votes, [:to_datetime])
	end
end
