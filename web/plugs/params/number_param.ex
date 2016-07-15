defmodule Democracy.Plugs.NumberParam do
	def handle(conn, value, opts) do
		if value == nil or String.length(value) == 0 do
			{:error, :bad_request, opts[:error]}
		else
			case Float.parse(value) do
				{value, _} ->
					{:ok, value}
				:error ->
					{:error, :bad_request, opts[:error]}
			end
		end
	end
end