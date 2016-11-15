defmodule Liquio.Repo.Migrations.CreateToken do
	use Ecto.Migration

	def change do
		create table(:tokens) do
			add :email, :string, null: false, size: 1000
			add :token, :string, null: false, size: 40
			add :is_valid, :boolean
			add :datetime, :datetime, null: false
		end
	end
end
