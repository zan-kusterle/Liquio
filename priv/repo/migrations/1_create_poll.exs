defmodule Democracy.Repo.Migrations.CreatePoll do
	use Ecto.Migration

	def change do
		create table(:polls) do
			add :kind, :string, null: false
			add :title, :string
			add :choices, {:array, :string}, null: false
			add :topics, {:array, :string}
			add :is_direct, :boolean, default: false

			timestamps
		end
	end
end
