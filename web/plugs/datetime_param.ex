defmodule Democracy.Plugs.DatetimeParam do
	def handle(conn, opts) do
		value = if Map.get(conn.params, opts[:name]) do
			time_text = conn.params[opts[:name]]
			case Timex.parse(time_text, "%Y-%m-%d", :strftime) do
				{:ok, datetime} ->
					Timex.DateTime.shift(datetime, days: 1)
				{:error, _} ->
					Timex.DateTime.now
			end
		else
			Timex.DateTime.now
		end
		{:ok, value}
	end
end