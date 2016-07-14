defmodule Democracy.Plugs.ItemParam do
	def handle(conn, opts) do
		item = Democracy.Repo.get(opts[:schema], conn.params[opts[:name]])
		if item != nil do
			{:ok, item}
		else
			{:error, :not_found, opts[:message] || "Not found"}
		end
	end
end