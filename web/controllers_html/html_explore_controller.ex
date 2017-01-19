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
		#|> Node.sort(sort)

		conn
		|> render("index.html",
			heading: "ALL POLLS",
			url: "",
			sort: sort,
			polls: nodes,
			identities: [])
	end

	def search(conn, %{"query" => query}) do
		polls = Poll |> Poll.search(query) |> Repo.all
		|> Enum.map(& PollHelper.prepare(&1, nil, nil, from_default_cache: true))
		conn
		|> render("index.html",
			heading: "RESULTS",
			query: query,
			polls: polls,
			identities: Identity |> Identity.search(query) |> Repo.all)
	end
end