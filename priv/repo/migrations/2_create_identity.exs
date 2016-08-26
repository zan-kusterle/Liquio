defmodule Liquio.Repo.Migrations.CreateIdentity do
	use Ecto.Migration

	def change do
		create table(:identities) do
			add :username, :string, null: false, size: 20
			add :password_hash, :string, null: false

			add :name, :string, null: false

			add :trust_metric_poll_id, references(:polls, on_delete: :nothing), null: false

			add :trust_metric_url, :string
			add :minimum_turnout, :float
			add :vote_weight_halving_days, :float
			add :approval_turnout_importance, :float
			add :approval_minimum_score, :float

			timestamps
		end

		create unique_index(:identities, [:username])
	end
end
