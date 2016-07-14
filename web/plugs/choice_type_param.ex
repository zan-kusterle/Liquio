defmodule Democracy.Plugs.ChoiceTypeParam do
	def handle(conn, opts) do
		value = Map.get(conn.params, opts[:name], "probability")
		if value == "from_topics" do
			topics = conn.params[opts[:topics_name]]
			value = if Enum.member?(topics, "quantity") do
				topics = Enum.filter(topics, & &1 != "quantity")
				#conn = %{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{topics_assign_atom => topics})}
				"quantity"
			else
				"probability"
			end
		end
		{:ok, value}
	end
end