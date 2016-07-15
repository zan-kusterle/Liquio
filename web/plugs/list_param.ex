defmodule Democracy.Plugs.ListParam do
	def handle(conn, value, opts) do
		if is_list(value) do
			{item_handler_module, item_handler_opts} = opts[:item]
			jobs = Enum.map(Enum.with_index(value), fn({i, x}) ->
				{i, {item_handler_module, x, item_handler_opts}}
			end)
			case Democracy.Plugs.Params.first_error_or_result(nil, jobs) do
				{:ok, value} ->
					value |> Map.values() |> Enum.filter(& &1 != nil)
				error ->
					error
			end
		else
			{:ok, []}
		end
	end
end