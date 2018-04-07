defmodule Liquio.Web.NodeController do
	use Liquio.Web, :controller
	
	alias Liquio.Node

	def search(conn, %{"query" => query}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		conn
		|> render("show.json", node: Node.search(query, calculation_opts))
	end

	def show(conn, %{"title" => title, "whitelist_url" => whitelist_url, "whitelist_usernames" => whitelist_usernames}) do
		node = Node.new(title)
		node = case Liquio.GetData.get(whitelist_url, String.split(whitelist_usernames, ",")) do
			{:ok, data} ->
				Node.load(node, data)
			{:error, message} ->
				node
		end

		conn
		|> render("show.json", node: node)
	end
end
