defmodule Liquio.Repo.Migrations.CreateVote do
	use Ecto.Migration

	def change do
		create table(:votes) do
			add :identity_id, references(:identities, on_delete: :nothing), null: false

			add :title, :string, null: false
			add :choice_type, :string, null: true # if reference_key is present
			add :key, :string, null: false

			add :reference_key, :string, null: true

			add :datetime, :datetime, null: false
			add :is_last, :boolean, null: false

			add :data, :map, null: true
		end

		create index(:votes, [:identity_id])
		create index(:votes, [:choice_type])
		create index(:votes, [:key])
		create index(:votes, [:reference_key])
		create index(:votes, [:datetime])
		create index(:votes, [:is_last])
	end
end
