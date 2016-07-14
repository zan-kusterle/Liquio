defmodule Democracy.Plugs.NumberParam do
	def handle(conn, opts) do
		value = Map.get(conn.params, opts[:name])
		if value == nil or String.length(value) == 0 do
			handle_error(conn, opts[:error])
		else
			case Float.parse(value) do
				{value, _} ->
					{:ok, value}
				:error ->
					handle_error(conn, opts[:error])
			end
		end
	end

	def handle_error(conn, message) do
		{
			:error, :bad_request,
			conn
			|> Phoenix.Controller.put_flash(:error, message)
		}
	end
end