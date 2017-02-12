defmodule Liquio.NodeController do
	use Liquio.Web, :controller
	
	with_params(%{
		:user => {Plugs.CurrentUser, [require: false]}
	},
	def index(conn, params = %{:user => user}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		nodes = Vote
		|> Repo.all
		|> Enum.map(& &1.key)
		|> Enum.uniq
		|> Enum.map(& Node.from_key(&1) |> Node.preload_results(calculation_opts))
		|> Enum.filter(& &1.choice_type != nil)
		conn
		|> render("show.json", node: Node.new("", nil) |> Map.put(:references, nodes) |> Map.put(:calculation_opts, calculation_opts))
	end)

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
