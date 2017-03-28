defmodule Liquio.Web.ReferenceVoteController do
	use Liquio.Web, :controller
	
	plug :scrub_params, "choice" when action in [:create]
	with_params(%{
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:reference_node => {Plugs.NodeParam, [name: "reference_id"]},
		:user => {Plugs.CurrentUser, [require: true]}
	},
	def create(conn, %{:node => node, :reference_node => reference_node, :user => user, "choice" => choice}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		reference = Node.put_reference_key(node, reference_node.key)

		Vote.set(reference, user, get_choice(choice))
		if MapSet.member?(calculation_opts.trust_metric_ids, to_string(user.id)) do
			{:info, "Your vote is now live."}
		else
			{:error, "Your vote is now live, but because you're not in trust metric it will not be counted. Get others to trust your identity by sharing it's URL to get into trust metric or change it in preferences."}
		end

		calculation_opts = Map.put(calculation_opts, :datetime, Timex.now)
		conn
		|> put_status(:created)
		|> render(Liquio.Web.NodeView, "show.json", node: NodeRepo.load(reference, calculation_opts, user))
	end)

	with_params(%{
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:reference_node => {Plugs.NodeParam, [name: "reference_id"]},
		:user => {Plugs.CurrentUser, [require: true]}
	},
	def delete(conn, %{:node => node, :reference_node => reference_node, :user => user}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		reference = Node.put_reference_key(node, reference_node.key)
		Vote.delete(reference, user)

		conn
		|> put_status(:created)
		|> render(Liquio.Web.NodeView, "show.json", node: NodeRepo.load(reference, calculation_opts, user))
	end)

	defp get_choice(v) do
		case Float.parse(v) do
			{:ok, x} -> x
			{:error, _} -> nil
		end
	end
end
