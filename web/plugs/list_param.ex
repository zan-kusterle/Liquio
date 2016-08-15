defmodule Liquio.Plugs.ListParam do
	def handle(conn, value, opts) do
		case handle_simple(conn, value, opts) do
			{:ok, value} ->
				if opts[:maybe] == true and Enum.empty?(value) do
					{:ok, nil}
				else
					{:ok, value}
				end
			{:error, status, message} ->
				if opts[:maybe] == true do
					{:ok, nil}
				else
					{:error, status, message}
				end
		end
	end

	defp handle_simple(conn, value, opts) do
		value = if is_bitstring(value) do
			value
			|> String.split(",")
			|> Enum.map(&String.trim/1)
			|> Enum.filter(& String.length(&1) > 0)
		else
			value
		end
		if is_list(value) do
			{item_handler_module, item_handler_opts} = opts[:item]
			jobs = Enum.map(Enum.with_index(value), fn({x, i}) ->
				{i, {item_handler_module, x, item_handler_opts}}
			end)
			case Liquio.Plugs.WithParams.first_error_or_result(conn, jobs) do
				{:ok, value} ->
					{:ok, value |> Map.values() |> Enum.filter(& &1 != nil)}
				{name, {:error, name, status, message}} ->
					{:error, status, message}
			end
		else
			{:ok, []}
		end
	end
end