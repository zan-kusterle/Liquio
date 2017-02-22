defmodule Liquio.ReferenceController do
	use Liquio.Web, :controller

	with_params(%{
		:user => {Plugs.CurrentUser, [require: false]},
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:reference_node => {Plugs.NodeParam, [name: "id"]}
	},
	def show(conn, %{:user => user, :node => node, :reference_node => reference_node}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		reference = Node.for_reference_key(node, reference_node.key) |> Node.preload(calculation_opts, user)
		conn
		|> render(Liquio.NodeView, "show.json", node: reference)
	end)
end