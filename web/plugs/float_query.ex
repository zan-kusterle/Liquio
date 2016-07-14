defmodule Democracy.Plugs.FloatQuery do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		value = Map.get(conn.params, query_name)
		if value == nil or String.length(value) == 0 do
			%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{assign_atom => nil})}
		else
			case Float.parse(value) do
				{value, _} ->
					%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{assign_atom => value})}
				:error ->
					%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{assign_atom => nil})}
			end
		end
	end

	def call(conn, {assign_atom, query_name, error_message}) do
		value = Map.get(conn.params, query_name)
		if value == nil or String.length(value) == 0 do
			handle_error(conn, error_message)
		else
			case Float.parse(value) do
				{value, _} ->
					%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{assign_atom => value})}
				:error ->
					handle_error(conn, error_message)
			end
		end
	end

	def handle_error(conn, message) do
	    case List.keyfind(conn.req_headers, "referer", 0) do
			{"referer", referer} ->
				url = URI.parse(referer)
				conn
				|> Phoenix.Controller.put_flash(:error, message)
				|> Phoenix.Controller.redirect to: url.path
			nil ->
				send_resp(conn, :bad_request, message)
				|> halt
		end
	end
end