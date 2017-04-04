defmodule Liquio.Repo.Migrations.CreateVote do
	use Ecto.Migration

	def change do
		create table(:votes) do
			add :identity_id, references(:identities, on_delete: :nothing), null: false

			add :path, {:array, :string}, null: false
			add :reference_path, {:array, :string}, null: false
			add :group_key, :string, null: false

			add :relevance, :float, null: true

			add :datetime, :utc_datetime, null: false
			add :is_last, :boolean, null: false
		end

		create index(:votes, [:identity_id])
		create index(:votes, [:path])
		create index(:votes, [:reference_path])
		create index(:votes, [:group_key])
		create index(:votes, [:datetime])
		create index(:votes, [:is_last])
	end
end
