defmodule Liquio.HtmlExploreController do
	use Liquio.Web, :controller

	with_params(%{
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]}
	},
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

		conn
		|> render(Liquio.ExploreView, "index.html",
			nodes: nodes,
			identities: [])
	end)

	def search(conn, %{"query" => query}) do
		polls = Poll |> Poll.search(query) |> Repo.all

		node = Node.new("Results for: #{query}", nil) |> Map.put(:references, polls)
		conn
		|> render("index.html",
			node: node,
			identities: Identity |> Identity.search(query) |> Repo.all)
	end
end