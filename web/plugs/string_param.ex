defmodule Liquio.Plugs.StringParam do
	def handle(conn, value, opts) do
		clean = if is_bitstring(value) do
			value = value |> String.trim
			if String.length(value) > 0 do
				if opts[:downcase] do
					value |> String.downcase
				else
					value
				end
			else
				nil
			end
		else
			nil
		end

		if clean != nil do
			{:ok, clean}
		else
			if opts[:maybe] == true do
				{:ok, nil}
			else
				{:error, :bad_request, "No string param"}
			end
		end
	end
end