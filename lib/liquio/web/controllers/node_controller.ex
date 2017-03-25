defmodule Liquio.Web.NodeController do
	use Liquio.Web, :controller
	
	def index(conn, _params) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		conn
		|> render("show.json", node: NodeRepo.all(calculation_opts))
	end

	def search(conn, %{"id" => query}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		conn
		|> render("show.json", node: NodeRepo.search(query, calculation_opts))
	end

	with_params(%{
		:node => {Plugs.NodeParam, [name: "id"]},
		:user => {Plugs.CurrentUser, [require: false]}
	},
	def show(conn, %{:node => node, :user => user}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		conn
		|> render("show.json", node: NodeRepo.preload(node, calculation_opts, user))
	end)
end
