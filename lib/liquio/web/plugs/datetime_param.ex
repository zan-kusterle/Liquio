defmodule Liquio.Plugs.DatetimeParam do
	def handle(_conn, value, _opts) do
		if is_bitstring(value) do
			case Timex.parse(value, "%Y-%m-%d", :strftime) do
				{:ok, datetime} ->
					{:ok, datetime}
				{:error, _} ->
					{:ok, Timex.now}
			end
		else
			{:ok, Timex.now}
		end
	end
end