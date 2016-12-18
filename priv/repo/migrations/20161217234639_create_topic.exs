defmodule Liquio.Repo.Migrations.CreateTopic do
	use Ecto.Migration

	def change do
		create table(:topics) do
			add :name, :string, null: false
			add :poll_id, references(:polls, on_delete: :nothing), null: false
			add :relevance_poll_id, references(:polls, on_delete: :nothing), null: false

			timestamps
		end

		create index(:topics, [:name])
		create index(:topics, [:poll_id])
		create index(:topics, [:relevance_poll_id])
		create unique_index(:topics, [:name, :poll_id])
	end
end
