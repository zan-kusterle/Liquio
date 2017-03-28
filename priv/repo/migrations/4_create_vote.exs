defmodule Liquio.Repo.Migrations.CreateVote do
	use Ecto.Migration

	def change do
		create table(:votes) do
			add :identity_id, references(:identities, on_delete: :nothing), null: false

			add :path, {:array, :string}, null: false
			add :reference_path, {:array, :string}, null: true
			add :filter_key, :string, null: true
			add :group_key, :string, null: false
			add :search_text, :string, null: false

			add :choice_type, :string, null: true
			add :choice, :float, null: true

			add :at_date, :date, null: false
			add :datetime, :utc_datetime, null: false
			add :is_last, :boolean, null: false
		end

		create index(:votes, [:identity_id])
		create index(:votes, [:choice_type])
		create unique_index(:votes, [:group_key])
		create index(:votes, [:datetime])
		create index(:votes, [:is_last])
	end
end
