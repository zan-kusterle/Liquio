defmodule Democracy.Plugs.Datetime do
	import Plug.Conn
	use Timex

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		assign(conn, assign_atom,
			if Map.get(conn.params, query_name) do
				time_text = conn.params[query_name]
				case Timex.parse(time_text, "%Y-%M-%d", :strftime) do
					{:ok, datetime} ->
						Ecto.DateTime.cast!(datetime)
					{:error, _} ->
						Ecto.DateTime.utc(:usec)
				end
			else
				Ecto.DateTime.utc(:usec)
			end
		)
	end
end