defmodule Democracy.Plugs.Params do
	import Plug.Conn

	def init(default), do: default

	def call(conn, list) do
		results = Enum.map(list, fn({handle, name, opts}) ->
			result = handle.(conn, opts)
			case result do
				{:ok, value} ->
					{:ok, name, [value: value]}
				{:error, status, message} ->
					{:error, name, [status: status, message: message]}
			end
		end)
		errors = Enum.filter(results, fn({status, name, data}) -> status == :error end)
		if Enum.count(errors) > 0 do
			conn
			|> put_status(:not_found)
			|> Phoenix.Controller.render(Democracy.ErrorView, "error.json", message: "Invalid query parameter")
			|> halt
		else
			params = for {:ok, name, data} <- results, into: %{} do
				{name, data[:value]}
			end
			%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(params)}
		end
	end
end