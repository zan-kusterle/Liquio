defmodule Liquio.Plugs.ItemParam do
	def handle(_conn, value, opts) do
		item = if opts[:column] == nil do
			Liquio.Repo.get(opts[:schema], value)
		else
			Liquio.Repo.get_by(opts[:schema], username: value)
		end
		
		if item != nil and (opts[:validator] == nil or opts[:validator].(item)) do
			{:ok, item}
		else
			if opts[:maybe] do
				{:ok, nil}
			else
				{:error, :not_found, opts[:message] || "Not found"}
			end
		end
	end
end