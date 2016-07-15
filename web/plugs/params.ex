defmodule Democracy.Plugs.Params do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {handler, list}) do
		if handler == nil or conn.private.phoenix_action == handler do
			results = Enum.map(list, fn({handle_module, name, opts}) ->
				result = handle_module.handle(conn, opts)
				case result do
					{:ok, value} ->
						{:ok, name, [value: value]}
					{:error, status, message} ->
						{:error, name, [status: status, message: message]}
				end
			end)
			errors = Enum.filter(results, fn({status, name, data}) -> status == :error end)
			if Enum.count(errors) > 0 do
				{:error, name, data} = Enum.at(errors, 0)

				conn
				|> put_status(data[:status])
				|> Phoenix.Controller.put_flash(:error, message: data[:message])
				|> Phoenix.Controller.redirect(to: "/polls/4")
				|> halt
			else
				params = for {:ok, name, data} <- results, into: %{} do
					{name, data[:value]}
				end
				%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(params)}
			end
		else
			conn
		end
	end

	def call(conn, list) do
		call(conn, {nil, list})
	end

	defmacro with_params(list, func) do
		name = func |> elem(2) |> Enum.at(0) |> elem(0)
		quote do
			plug Democracy.Plugs.Params, {unquote(name), unquote(list)}
			unquote(func)
		end
	end
end