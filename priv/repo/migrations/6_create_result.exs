defmodule Democracy.Repo.Migrations.CreateVote do
	use Ecto.Migration

	def change do
		create table(:results) do
			add :poll_id, references(:polls, on_delete: :nothing), null: false
			add :datetime, :datetime, null: false
			add :data, :map, null: false
		end

		create index(:results, [:poll_id])
		create index(:results, [:datetime])
	end
end
