defmodule Democracy.Plugs.ItemParam do
	def handle(conn, value, opts) do
		item = Democracy.Repo.get(opts[:schema], conn.params[opts[:name]])
		if item != nil do
			if validator = opts[:validator] do
				if validator.(item) do
					{:ok, item}
				else
					{:error, :not_found, opts[:message] || "Not found"}
				end
			else
				{:ok, item}
			end

		else
			{:error, :not_found, opts[:message] || "Not found"}
		end
	end
end