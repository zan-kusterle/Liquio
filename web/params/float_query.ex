defmodule Democracy.Plugs.FloatQuery do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		value = Map.get(conn.params, query_name)
		if value == nil or String.length(value) == 0 do
			send_resp(conn, :bad_request, "Unable to parse float from param #{query_name}")
			|> halt
		else
			case Float.parse(value) do
				{value, _} ->
					%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{assign_atom => value})}
				:error ->
					send_resp(conn, :bad_request, "Unable to parse float from param #{query_name}")
					|> halt
			end
		end
	end

	def call(conn, {assign_atom, query_name, error_message}) do
		value = Map.get(conn.params, query_name)
		if value == nil or String.length(value) == 0 do
			case List.keyfind(conn.req_headers, "referer", 0) do
				{"referer", referer} ->
					url = URI.parse(referer)
					conn
					|> Phoenix.Controller.put_flash(:error, error_message)
					|> Phoenix.Controller.redirect to: url.path
				nil ->
					send_resp(conn, :bad_request, "Unable to parse float from param #{query_name}")
                    |> halt
			end
		else
			case Float.parse(value) do
				{value, _} ->
					%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{assign_atom => value})}
				:error ->
					case List.keyfind(conn.req_headers, "referer", 0) do
						{"referer", referer} ->
							url = URI.parse(referer)
							conn
							|> Phoenix.Controller.put_flash(:error, error_message)
							|> Phoenix.Controller.redirect to: url.path
						nil ->
							send_resp(conn, :bad_request, "Unable to parse float from param #{query_name}")
							|> halt
					end
			end
		end
	end
end