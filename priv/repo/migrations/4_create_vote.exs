defmodule Democracy.Repo.Migrations.CreateVote do
	use Ecto.Migration

	def change do
		create table(:votes) do
			add :poll_id, references(:polls, on_delete: :nothing)
			add :identity_id, references(:identities, on_delete: :nothing)
			add :choice, :string
			add :score, :float

			timestamps
		end

		create index(:votes, [:poll_id])
		create index(:votes, [:identity_id])
		create index(:votes, [:poll_id, :choice])
	end
end
