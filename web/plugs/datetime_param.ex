defmodule Liquio.Plugs.DatetimeParam do
	def handle(conn, value, opts) do
		if is_bitstring(value) do
			case Timex.parse(value, "%Y-%m-%d", :strftime) do
				{:ok, datetime} ->
					{:ok, datetime}
				{:error, _} ->
					{:ok, Timex.DateTime.now}
			end
		else
			{:ok, Timex.DateTime.now}
		end
	end
end