defmodule Democracy.Repo.Migrations.CreateReference do
	use Ecto.Migration

	def change do
		create table(:references) do
			add :poll_id, references(:polls, on_delete: :nothing), null: false
			add :reference_poll_id, references(:polls, on_delete: :nothing)
			add :approval_poll_id, references(:polls, on_delete: :nothing), null: false
			add :for_choice, :float, null: false

			timestamps
		end

		create index(:references, [:poll_id])
		create index(:references, [:reference_poll_id])
		create index(:references, [:approval_poll_id])
		create unique_index(:references, [:poll_id, :reference_poll_id, :for_choice])
	end
end
