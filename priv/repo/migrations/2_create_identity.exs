defmodule Democracy.Repo.Migrations.CreateIdentity do
	use Ecto.Migration

	def change do
		create table(:identities) do
			add :username, :string, null: false, size: 20
			add :token, :string, null: false

			add :name, :string, null: false

			add :trust_metric_poll_id, references(:polls, on_delete: :nothing), null: false

			add :trust_metric_url, :string
			add :vote_weight_halving_days, :integer

			timestamps
		end

		create unique_index(:identities, [:username])
	end
end
