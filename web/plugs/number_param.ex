defmodule Democracy.Plugs.NumberParam do
	def handle(conn, value, opts) do
		IO.inspect value
		if value == nil or String.length(value) == 0 do
			if opts[:maybe] == true do
				{:ok, nil}
			else
				{:error, :bad_request, opts[:error]}
			end
		else
			if opts[:whole] == true do
				{x, _} = Integer.parse(value)
				{:ok, x}
			else
				case Float.parse(value) do
					{value, _} ->
						{:ok, value}
					:error ->
						if opts[:maybe] == true do
							{:ok, nil}
						else
							{:error, :bad_request, opts[:error]}
						end
				end
			end
		end
	end
end