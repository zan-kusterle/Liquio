defmodule Liquio.Web.VoteController do
	use Liquio.Web, :controller
	
	plug :scrub_params, "choice" when action in [:create]
	with_params(%{
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:user => {Plugs.CurrentUser, [require: true]}
	},
	def create(conn, %{:node => node, :user => user, "choice" => choice}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)

		Vote.set(node, user, choice)
		if MapSet.member?(calculation_opts.trust_metric_ids, to_string(user.id)) do
			{:info, "Your vote is now live."}
		else
			{:error, "Your vote is now live, but because you're not in trust metric it will not be counted. Get others to trust your identity by sharing it's URL to get into trust metric or change it in preferences."}
		end

		calculation_opts = Map.put(calculation_opts, :datetime, Timex.now)
		conn
		|> put_status(:created)
		|> put_resp_header("location", node_path(conn, :show, node.key))
		|> render(Liquio.Web.NodeView, "show.json", node: Node.preload(node, calculation_opts, user))
	end)

	with_params(%{
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:user => {Plugs.CurrentUser, [require: true]}
	},
	def delete(conn, %{:node => node, :user => user}) do
		vote = Vote.delete(node, user)

		calculation_opts = CalculationOpts.get_from_conn(conn)
		conn
		|> put_status(:created)
		|> put_resp_header("location", node_path(conn, :show, node.key))
		|> render(Liquio.Web.NodeView, "show.json", node: Node.preload(node, calculation_opts, user))
	end)
end
