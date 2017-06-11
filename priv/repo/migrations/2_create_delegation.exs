defmodule Liquio.Repo.Migrations.CreateDelegation do
	use Ecto.Migration

	def change do
		create table(:delegations) do
			add :signature_id, references(:signatures, on_delete: :nothing), null: false
			add :username, :string, null: false

			add :to_username, :string, null: false

			add :is_trusting, :boolean, null: true
			add :weight, :float, null: true
			add :topics, {:array, :string}, null: true

			add :datetime, :utc_datetime, null: false
			add :to_datetime, :utc_datetime, null: true
		end
		
		create index(:delegations, [:username])
		create index(:delegations, [:to_username])
		create index(:delegations, [:datetime])
		create index(:delegations, [:to_datetime])
	end
end
