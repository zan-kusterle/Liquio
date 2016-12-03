defmodule Liquio.Repo.Migrations.CreateReference do
	use Ecto.Migration

	def change do
		create table(:references) do
			add :poll_id, references(:polls, on_delete: :nothing), null: false
			add :reference_poll_id, references(:polls, on_delete: :nothing)
			add :for_choice_poll_id, references(:polls, on_delete: :nothing), null: false

			timestamps
		end

		create index(:references, [:poll_id])
		create index(:references, [:reference_poll_id])
		create index(:references, [:for_choice_poll_id])
		create unique_index(:references, [:poll_id, :reference_poll_id])
	end
end
