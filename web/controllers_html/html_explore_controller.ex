defmodule Liquio.HtmlExploreController do
	use Liquio.Web, :controller

	def index(conn, params) do
		sort = Map.get(params, "sort", "top")
		calculation_opts = get_calculation_opts_from_conn(conn)
		nodes = Vote
		|> Repo.all
		|> Enum.map(& &1.key)
		|> Enum.uniq
		|> Enum.map(& Node.from_key(&1) |> Node.preload_results(calculation_opts))
		|> Enum.filter(& &1.choice_type != nil)
		#|> Node.sort(sort)

		node = Node.new("List Of All Polls", nil) |> Map.put(:references, nodes)
		conn
		|> render("index.html",
			calculation_opts: calculation_opts,
			node: node,
			identities: [])
	end

	def search(conn, %{"query" => query}) do
		polls = Poll |> Poll.search(query) |> Repo.all
		|> Enum.map(& PollHelper.prepare(&1, nil, nil, from_default_cache: true))

		node = Node.new("Results for: #{query}", nil) |> Map.put(:references, polls)
		conn
		|> render("index.html",
			node: node,
			identities: Identity |> Identity.search(query) |> Repo.all)
	end
end