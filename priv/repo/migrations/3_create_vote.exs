defmodule Liquio.Repo.Migrations.CreateVote do
	use Ecto.Migration

	def change do
		create table(:votes) do
			add :signature_id, references(:signatures, on_delete: :nothing), null: false
			add :username, :string, null: false

			add :path, {:array, :text}, null: false
			add :unit, :string, null: false
			add :at_date, :date, null: false
			add :group_key, :text, null: false

			add :choice, :float, null: false
			
			add :datetime, :utc_datetime, null: false
			add :to_datetime, :utc_datetime, null: true
			add :search_text, :text, null: false
		end

		create index(:votes, [:username])
		create index(:votes, [:path])
		create index(:votes, [:group_key])
		create index(:votes, [:datetime])
		create index(:votes, [:to_datetime])

		execute "CREATE extension if not exists pg_trgm;"
		execute "CREATE INDEX votes_search_trgm_index ON votes USING gin (search_text gin_trgm_ops);"
	end
end
