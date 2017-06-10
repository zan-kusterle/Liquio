defmodule Liquio.Repo.Migrations.AddTokens do
	use Ecto.Migration

	def change do
		create table(:signatures) do
			add :public_key, :string, null: false
			add :data, :string, null: false
			add :data_hash, :string, null: false
			add :signature, :string, null: false
			add :ipfs_hash, :string, null: false
		end
	end
end
