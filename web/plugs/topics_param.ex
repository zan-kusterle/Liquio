defmodule Democracy.Plugs.TopicsParam do
	def handle(conn, opts) do
		topics = to_string(Map.get(conn.params, opts[:name], ""))
		|> String.split(",")
		|> Enum.map(&String.trim/1)
		|> Enum.filter(& String.length(&1) > 0)
        {:ok, topics}
	end
end