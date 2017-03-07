defmodule Liquio.Plugs.BooleanParam do
	def handle(_conn, value, _opts) do
		{:ok, value == "1" or value == "true"}
	end
end