defmodule Liquio.Plugs.ItemParam do
	def handle(_conn, value, opts) do
		case Integer.parse(value) do
			{value, _} ->
				item = Liquio.Repo.get(opts[:schema], value)
				if item != nil and (opts[:validator] == nil or opts[:validator].(item)) do
					{:ok, item}
				else
					{:error, :not_found, opts[:message] || "Not found"}
				end
			:error ->
				{:error, :not_found, opts[:message] || "Not found"}
		end
		
	end
end