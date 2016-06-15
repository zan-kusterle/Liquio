defmodule Democracy.Repo.Migrations.CreateTrustMetric do
	use Ecto.Migration

	def change do
		create table(:trust_metrics) do
			add :identity_id, references(:identities, on_delete: :nothing), null: false
			add :key, :string, null: false
		end

		create index(:trust_metrics, [:identity_id])
		create index(:trust_metrics, [:key])
		create unique_index(:trust_metrics, [:identity_id, :key])
	end
end
