defmodule Liquio.Web.NodeController do
	use Liquio.Web, :controller
	
	alias Liquio.Node

	def search(conn, %{"query" => query}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		conn
		|> render("show.json", node: Node.search(query, calculation_opts))
	end

	def show(conn, params = %{"title" => title}) do
		whitelist_url = Map.get(params, "whitelist_url")
		whitelist_usernames =  Map.get(params, "whitelist_usernames", "")
		|> String.split(",")
		|> Enum.filter(& String.length(&1) > 0)

		node = Node.new(title)
		node = case Liquio.GetData.get_using_cache(whitelist_url, whitelist_usernames) do
			{:ok, data} ->
				Node.load(node, data)
			{:error, message} ->
				node
		end

		conn
		|> render("show.json", node: node)
	end
end
