defmodule Liquio.Repo.Migrations.CreatePoll do
	use Ecto.Migration

	def change do
		create table(:polls) do
			add :kind, :string, null: false
			add :choice_type, :string, null: false
			add :title, :string, size: 5000
			add :latest_default_results, :map, null: true

			timestamps
		end
	end
end
