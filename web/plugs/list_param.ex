defmodule Democracy.Plugs.ListParam do
	def handle(conn, value, opts) do
		if is_bitstring(value) do
			value = value
			|> String.split(",")
			|> Enum.map(&String.trim/1)
		end
		if is_list(value) do
			{item_handler_module, item_handler_opts} = opts[:item]
			jobs = Enum.map(Enum.with_index(value), fn({x, i}) ->
				{i, {item_handler_module, x, item_handler_opts}}
			end)
			case Democracy.Plugs.Params.first_error_or_result(conn, jobs) do
				{:ok, value} ->
					{:ok, value |> Map.values() |> Enum.filter(& &1 != nil)}
				error ->
					error
			end
		else
			{:ok, []}
		end
	end
end