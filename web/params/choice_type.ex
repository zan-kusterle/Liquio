defmodule Democracy.Plugs.ChoiceType do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, query_name, topics_assign_atom}) do
		value = Map.get(conn.params, query_name, "probability")
		if value == "from_topics" do
			topics = conn.params[topics_assign_atom]
			value = if Enum.member?(topics, "quantity") do
				topics = Enum.filter(topics, & &1 != "quantity")
				conn = %{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{topics_assign_atom => topics})}
				"quantity"
			else
				"probability"
			end
		end

		%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{assign_atom => value})}
	end
end