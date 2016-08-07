defmodule Liquio.Repo.Migrations.CreateVote do
	use Ecto.Migration

	def change do
		create table(:votes) do
			add :poll_id, references(:polls, on_delete: :nothing), null: false
			add :identity_id, references(:identities, on_delete: :nothing), null: false

			add :datetime, :datetime, null: false
			add :is_last, :boolean, null: false

			add :data, :map, null: true
		end

		create index(:votes, [:poll_id])
		create index(:votes, [:identity_id])
		create index(:votes, [:datetime])
		create index(:votes, [:is_last])
	end
end
