defmodule Democracy.Plugs.Datetime do
	import Plug.Conn
	use Timex

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		value = if Map.get(conn.params, query_name) do
			time_text = conn.params[query_name]
			case Timex.parse(time_text, "%Y-%m-%d", :strftime) do
				{:ok, datetime} ->
					Timex.DateTime.shift(datetime, days: 1)
				{:error, _} ->
					Timex.DateTime.now
			end
		else
			Timex.DateTime.now
		end
		%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{assign_atom => value})}
	end
end