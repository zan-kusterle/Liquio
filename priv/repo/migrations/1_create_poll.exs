defmodule Democracy.Repo.Migrations.CreatePoll do
	use Ecto.Migration

	def change do
		create table(:polls) do
			add :kind, :string, null: false
			add :title, :string
			add :source_urls, {:array, :string}
			add :topics, {:array, :string}

			timestamps
		end
	end
end
