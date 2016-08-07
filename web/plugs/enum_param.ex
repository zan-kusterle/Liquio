defmodule Liquio.Plugs.EnumParam do
	def handle(conn, value, opts) do
		if value == nil do
			if opts[:maybe] do
				{:ok, nil}
			else
				{:error, :bad_request, "Cant parse enum"}
			end
		else
			if Enum.member?(opts[:values], value) do
				{:ok, value}
			else
				{:error, :bad_request, "Not a valid value"}
			end
		end
	end
end