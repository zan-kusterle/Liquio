defmodule Democracy.Plugs.ItemParam do
	def handle(conn, value, opts) do
		item = Democracy.Repo.get(opts[:schema], value)
		if item != nil and (opts[:validator] == nil or opts[:validator].(item)) do
			{:ok, item}
		else
			{:error, :not_found, opts[:message] || "Not found"}
		end
	end
end