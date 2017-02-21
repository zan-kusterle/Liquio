defmodule Liquio.NodeController do
	use Liquio.Web, :controller
	
	def index(conn, _params) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		nodes = Vote
		|> Repo.all
		|> Enum.map(& &1.key)
		|> Enum.uniq
		|> Enum.map(& Node.from_key(&1) |> Node.preload_results(calculation_opts) |> Node.preload_references(calculation_opts))
		|> Enum.filter(& &1.choice_type != nil)
		|> Enum.sort_by(& -(&1.results.turnout_ratio + 0.05 * Enum.count(&1.references)))
		conn
		|> render("show.json", node: Node.new("", nil) |> Map.put(:references, nodes) |> Map.put(:calculation_opts, calculation_opts))
	end

	def search(conn, %{"id" => query}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		nodes = Vote
		|> Vote.search(query)
		|> Repo.all
		|> Enum.map(& &1.key)
		|> Enum.uniq
		|> Enum.map(& Node.from_key(&1) |> Node.preload_results(calculation_opts))

		conn
		|> render("show.json", node: Node.new("Results for '#{query}'", nil) |> Map.put(:references, nodes) |> Map.put(:calculation_opts, calculation_opts))
	end

	with_params(%{
		:node => {Plugs.NodeParam, [name: "id"]},
		:user => {Plugs.CurrentUser, [require: false]}
	},
	def show(conn, %{:node => node, :user => user}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		conn
		|> render("show.json", node: Node.preload(node, calculation_opts, user))
	end)
end
