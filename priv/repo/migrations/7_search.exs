defmodule Liquio.Repo.Migrations.Search do
	use Ecto.Migration

	def up do
		execute "CREATE extension if not exists pg_trgm;"
		execute "CREATE INDEX votes_title_trgm_index ON votes USING gin (title gin_trgm_ops);"
	end

	def down do
		execute "DROP INDEX votes_title_trgm_index;"
	end
end
