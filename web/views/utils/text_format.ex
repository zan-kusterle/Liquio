defmodule Liquio.TextFormat do
	def truncate(s, max_length) do
		if String.length(s) > max_length do
			String.slice(s, 0, max_length - 3) <> "..."
		else
			s
		end
	end
end