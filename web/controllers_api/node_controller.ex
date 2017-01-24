defmodule Liquio.NodeController do
	use Liquio.Web, :controller
	
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
