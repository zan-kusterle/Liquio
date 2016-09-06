defmodule Liquio.Plugs.ChoiceParam do
	def handle(_conn, value, opts) do
		{:ok, value == "1" or value == "true"}
	end
end