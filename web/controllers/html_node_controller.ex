defmodule Liquio.HtmlNodeController do
	use Liquio.Web, :controller

	with_params(%{
		:node => {Plugs.NodeParam, [name: "id"]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
		:user => {Plugs.CurrentUser, [require: false]}
	},
	def show(conn, params = %{:node => node, :user => user}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render(Liquio.NodeView, "show.html",
			view: :full,
			conn: conn,
			calculation_opts: calculation_opts,
			node: Node.preload(node, calculation_opts, user))
	end)

	plug :put_layout, "minimal.html" when action in [:embed]
	with_params(%{
		:node => {Plugs.NodeParam, [name: "html_node_id"]},
	},
	def embed(conn, %{:node => node}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("embed.html",
			poll: Node.preload(node, calculation_opts, nil))
	end)
end