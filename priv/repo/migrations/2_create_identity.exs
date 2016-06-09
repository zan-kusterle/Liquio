defmodule Democracy.Repo.Migrations.CreateIdentity do
	use Ecto.Migration

	def change do
		create table(:identities) do
			add :username, :string
			add :token, :string

			add :name, :string

			add :trust_metric_poll_id, references(:polls, on_delete: :nothing)

			timestamps
		end

		create unique_index(:identities, [:username])
	end
end
