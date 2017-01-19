defmodule Liquio.Repo.Migrations.CreateIdentity do
	use Ecto.Migration

	def change do
		create table(:identities) do
			add :email, :string, null: false, size: 1000
			add :username, :string, null: false, size: 20
			add :name, :string, null: false

			add :trust_metric_url, :string
			add :minimum_turnout, :float
			add :vote_weight_halving_days, :float
			add :reference_minimum_turnout, :float
			add :reference_minimum_agree, :float

			timestamps
		end

		create unique_index(:identities, [:email])
		create unique_index(:identities, [:username])
	end
end
