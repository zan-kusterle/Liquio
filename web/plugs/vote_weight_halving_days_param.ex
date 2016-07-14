defmodule Democracy.Plugs.VoteWeightHalvingDaysParam do
	def handle(conn, opts) do
		value = if Map.get(conn.params, opts[:name]) do
			{value, _} = Integer.parse(conn.params[opts[:name]])
			value
		else
			nil
		end
		{:ok, value}
	end
end