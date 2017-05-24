defmodule Liquio.Web.ReferenceController do
	use Liquio.Web, :controller

	with_params(%{
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:reference_node => {Plugs.NodeParam, [name: "id"]}
	},
	def show(conn, %{:node => node, :reference_node => reference_node}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		reference = Reference.new(node.path, reference_node.path) |> ReferenceRepo.load(calculation_opts)

		conn
		|> render(Liquio.Web.NodeView, "reference.json", node: reference)
	end)

	with_params(%{
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:reference_node => {Plugs.NodeParam, [name: "id"]}
	},
	def update(conn, %{:node => node, :reference_node => reference_node, "public_key" => public_key, "signature" => signature, "relevance" => relevance}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		reference = Reference.new(node.path, reference_node.path)
		
		ReferenceVote.set(Base.decode64!(public_key), Base.decode64!(signature), reference, get_relevance(relevance))

		calculation_opts = Map.put(calculation_opts, :datetime, Timex.now)
		conn
		|> put_status(:created)
		|> render(Liquio.Web.NodeView, "reference.json", node: ReferenceRepo.load(reference, calculation_opts))
	end)

	with_params(%{
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:reference_node => {Plugs.NodeParam, [name: "id"]}
	},
	def delete(conn, %{:node => node, :reference_node => reference_node, "public_key" => public_key, "signature" => signature}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		reference = Reference.new(node.path, reference_node.path)
		ReferenceVote.delete(Base.decode64!(public_key), Base.decode64!(signature), reference)

		conn
		|> put_status(:created)
		|> render(Liquio.Web.NodeView, "show.json", node: NodeRepo.load(reference, calculation_opts))
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