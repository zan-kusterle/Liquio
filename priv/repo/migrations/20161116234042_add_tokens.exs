defmodule Liquio.Repo.Migrations.AddTokens do
	use Ecto.Migration

	def change do
		create table(:tokens) do
			add :email, :string, null: false, size: 1000
			add :token, :string, null: false
			add :is_valid, :boolean
			add :datetime, :utc_datetime, null: false
		end
	end
end
