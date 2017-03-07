defmodule Liquio.Plugs.WithParams do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {action, map}) do
		if action == nil or conn.private.phoenix_action == action do
			names = Map.keys(map)
			jobs = Enum.map(names, fn(name) ->
				{handler_module, opts} = map[name]
				{name, {handler_module, Map.get(conn.params, opts[:name]), opts}}
			end)
			case first_error_or_result(conn, jobs) do
				{:ok, params} ->
					%{conn | params: conn.params |> Map.merge(params)}
				{:error, name, status, message} ->
					conn
					|> put_status(status)
					|> Phoenix.Controller.render(Liquio.Web.ErrorView, "error.json", message: "Unable to fetch param #{name}: #{message}")
					|> halt
			end
		else
			conn
		end
	end

	def call(conn, list) do
		call(conn, {nil, list})
	end

	def first_error_or_result(conn, handlers) do
		results = Enum.map(handlers, fn({name, {handler, value, opts}}) ->
			{name, handler.handle(conn, value, opts)}
		end)
		error_results = results |> Enum.filter(fn({_name, data}) ->
			elem(data, 0) == :error
		end)
		if Enum.empty?(error_results) do
			{
				:ok,
				results
				|> Enum.map(fn({name, {:ok, value}}) -> {name, value} end)
				|> Enum.into(%{})
			}
		else
			{name, {:error, status, message}} = Enum.at(error_results, 0)
			{:error, name, status, message}
		end
	end

	defmacro with_params(list, func) do
		name = func |> elem(2) |> Enum.at(0) |> elem(0)
		quote do
			plug Liquio.Plugs.WithParams, {unquote(name), unquote(list)}
			unquote(func)
		end
	end
end