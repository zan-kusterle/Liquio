defmodule Democracy.Repo.Migrations.CreateDelegation do
	use Ecto.Migration

	def change do
		create table(:delegations) do
			add :from_identity_id, references(:identities, on_delete: :nothing), null: false
			add :to_identity_id, references(:identities, on_delete: :nothing), null: false

			add :weight, :float, null: false, default: 1.0
			add :topics, {:array, :string}

			timestamps
		end
		
		create index(:delegations, [:from_identity_id])
		create index(:delegations, [:to_identity_id])
	end
end
