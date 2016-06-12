defmodule Democracy.Repo.Migrations.CreateVote do
	use Ecto.Migration

	def change do
		create table(:references) do
			add :poll_id, references(:polls, on_delete: :nothing), null: false
			add :reference_poll_id, references(:polls, on_delete: :nothing)
			add :reference_document_id, references(:polls, on_delete: :nothing)
			add :approval_poll_id, references(:polls, on_delete: :nothing), null: false
			add :reference_kind, :string, null: false
			add :choice, :string, null: false
			add :pole, :string, null: false

			timestamps
		end

		create index(:references, [:poll_id])
		create index(:references, [:reference_poll_id])
		create index(:references, [:reference_document_id])
		create index(:references, [:approval_poll_id])
		create unique_index(:references, [:poll_id, :reference_poll_id, :reference_document_id, :reference_kind, :choice, :pole])
	end
end
