defmodule Democracy.Repo.Migrations.CreatePoll do
	use Ecto.Migration

	def change do
		create table(:polls) do
			add :kind, :string, null: false
			add :choice_type, :string, null: false
			add :title, :string
			add :topics, {:array, :string}
			add :is_binary, :boolean

			timestamps
		end
	end
end
