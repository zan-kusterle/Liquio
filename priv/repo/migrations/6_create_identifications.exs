defmodule Liquio.Repo.Migrations.CreateIdentifications do
	use Ecto.Migration

	def change do
		create table(:identifications) do
			add :signature_id, references(:signatures, on_delete: :nothing), null: false
			add :username, :string, null: false

			add :key, :string, null: false
			add :name, :string, null: false

			add :datetime, :utc_datetime, null: false
			add :to_datetime, :utc_datetime, null: true
		end
		
		create index(:identifications, [:username])
		create index(:identifications, [:datetime])
		create index(:identifications, [:to_datetime])
	end
end
