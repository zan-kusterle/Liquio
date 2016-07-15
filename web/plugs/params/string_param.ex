defmodule Democracy.Plugs.StringParam do
	def handle(conn, value, opts) do
		clean = if is_bitstring(value) do
			value = value |> String.trim
			if String.length(value) > 0 do
				value
			else
				nil
			end
		else
			nil
		end

		if clean != nil do
			{:ok, clean}
		else
			if opts[:require] do
				{:error, :bad_request, "No string param"}
			else
				{:ok, nil}
			end
		end
	end
end