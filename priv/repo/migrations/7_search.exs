defmodule Liquio.Repo.Migrations.Search do
	use Ecto.Migration

	def up do
		execute "CREATE extension if not exists pg_trgm;"
		execute "CREATE INDEX votes_search_trgm_index ON votes USING gin (search_text gin_trgm_ops);"
	end

	def down do
		execute "DROP INDEX votes_search_trgm_index;"
	end
end
