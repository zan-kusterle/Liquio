defmodule Democracy.Repo.Migrations.CreatePoll do
	use Ecto.Migration

	def change do
		create table(:polls) do
			add :title, :string
			add :choices, {:array, :string}
			add :topics, {:array, :string}
			add :is_direct, :boolean

			timestamps
		end
	end
end
