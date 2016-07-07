defmodule Democracy.Repo.Migrations.PollSearch do
	use Ecto.Migration

	def up do
		execute "CREATE extension if not exists pg_trgm;"
		execute "CREATE INDEX polls_title_trgm_index ON polls USING gin (title gin_trgm_ops);"
	end

	def down do
		execute "DROP INDEX polls_title_trgm_index;"
	end
end
