defmodule Democracy.Plugs.Datetime do
	import Plug.Conn
	use Timex

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		assign(conn, assign_atom,
			if Map.get(conn.params, query_name) do
				time_text = conn.params[query_name]
				{:ok, datetime} = Timex.parse(time_text, "%Y-%M-%d", :strftime)
				Ecto.DateTime.cast!(datetime)
			else
				Ecto.DateTime.utc(:usec)
			end
		)
	end
end