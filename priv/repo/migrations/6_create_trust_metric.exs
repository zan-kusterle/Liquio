defmodule Liquio.Repo.Migrations.CreateTrustMetric do
	use Ecto.Migration

	def change do
		create table(:trust_metrics) do
			add :url, :string, null: false
			add :last_update, :datetime, null: false
			add :usernames, {:array, :string}, null: false
		end

		create unique_index(:trust_metrics, [:url])
	end
end
