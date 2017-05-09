defmodule Liquio.Repo.Migrations.CreateIdentity do
	use Ecto.Migration

	def change do
		create table(:identities) do
			add :email, :string, null: false, size: 1000
			add :username, :string, null: false, size: 20
			add :name, :string, null: false
			
			timestamps()
		end

		create unique_index(:identities, [:email])
		create unique_index(:identities, [:username])
	end
end
