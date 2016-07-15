defmodule Democracy.Plugs.TitleParam do
	def handle(conn, opts) do
		if value = Map.get(conn.params, opts[:name]) do
			value = value |> String.trim
			{:ok, value}
		else
			{:error, :not_found, "Unable to retrieve title param"}
		end
	end
end