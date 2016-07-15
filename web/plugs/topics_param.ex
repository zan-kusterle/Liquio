defmodule Democracy.Plugs.TopicsParam do
	def handle(conn, value, opts) do
		topics = to_string(value)
		|> String.split(",")
		|> Enum.map(&String.trim/1)
		|> Enum.filter(& String.length(&1) > 0)
        {:ok, topics}
	end
end