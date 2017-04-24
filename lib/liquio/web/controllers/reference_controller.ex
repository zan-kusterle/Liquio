defmodule Liquio.Web.ReferenceController do
	use Liquio.Web, :controller

	with_params(%{
		:user => {Plugs.CurrentUser, [require: false]},
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:reference_node => {Plugs.NodeParam, [name: "id"]}
	},
	def show(conn, %{:user => user, :node => node, :reference_node => reference_node}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		reference = Reference.new(node.path, reference_node.path) |> ReferenceRepo.load(calculation_opts, user)

		conn
		|> render(Liquio.Web.NodeView, "reference.json", node: reference)
	end)

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:reference_node => {Plugs.NodeParam, [name: "id"]}
	},
	def update(conn, %{:node => node, :reference_node => reference_node, :user => user, "relevance" => relevance}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		reference = Reference.new(node.path, reference_node.path)
		
		ReferenceVote.set(user, reference, get_relevance(relevance))
		if MapSet.member?(calculation_opts.trust_metric_ids, to_string(user.id)) do
			{:info, "Your vote is now live."}
		else
			{:error, "Your vote is now live, but because you're not in trust metric it will not be counted. Get others to trust your identity by sharing it's URL to get into trust metric or change it in preferences."}
		end

		calculation_opts = Map.put(calculation_opts, :datetime, Timex.now)
		conn
		|> put_status(:created)
		|> render(Liquio.Web.NodeView, "reference.json", node: ReferenceRepo.load(reference, calculation_opts, user))
	end)

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:reference_node => {Plugs.NodeParam, [name: "id"]}
	},
	def delete(conn, %{:node => node, :reference_node => reference_node, :user => user}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		reference = Reference.new(node.path, reference_node.path)
		ReferenceVote.delete(user, reference)

		conn
		|> put_status(:created)
		|> render(Liquio.Web.NodeView, "show.json", node: NodeRepo.load(reference, calculation_opts, user))
	end)

	defp get_relevance(v) do
		if is_binary(v) do
			case Float.parse(v) do
				{x, _} -> x
				:error -> nil
			end
			v
		else
			if is_integer(v) do
				v * 1.0
			else
				v
			end
		end
	end
end