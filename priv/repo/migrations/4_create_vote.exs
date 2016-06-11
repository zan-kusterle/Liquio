defmodule Democracy.Repo.Migrations.CreateVote do
	use Ecto.Migration

	def change do
		create table(:votes) do
			add :poll_id, references(:polls, on_delete: :nothing), null: false
			add :identity_id, references(:identities, on_delete: :nothing), null: false
			add :choice, :string, null: false
			add :score, :float, null: false

			timestamps
		end

		create index(:votes, [:poll_id])
		create index(:votes, [:identity_id])
		create index(:votes, [:poll_id, :choice])
	end
end
