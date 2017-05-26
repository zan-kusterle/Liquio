defmodule Liquio.Web.ReferenceController do
	use Liquio.Web, :controller

	def show(conn, %{"node_id" => id, "id" => reference_id}) do
		node = Node.decode(id)
		reference_node = Node.decode(reference_id)
		calculation_opts = CalculationOpts.get_from_conn(conn)
		reference = Reference.new(node.path, reference_node.path) |> Reference.load(calculation_opts)

		conn
		|> render(Liquio.Web.ReferenceView, "show.json", reference: reference)
	end

	def update(conn, %{"node_id" => id, "id" => reference_id, "public_key" => public_key, "signature" => signature, "relevance" => relevance}) do
		node = Node.decode(id)
		reference_node = Node.decode(reference_id)
		calculation_opts = CalculationOpts.get_from_conn(conn)
		reference = Reference.new(node.path, reference_node.path)
		
		ReferenceVote.set(Base.decode64!(public_key), Base.decode64!(signature), reference, get_relevance(relevance))
		calculation_opts = Map.put(calculation_opts, :datetime, Timex.now)
		reference = Reference.load(reference, calculation_opts)
		
		conn
		|> put_status(:created)
		|> render(Liquio.Web.ReferenceView, "show.json", reference: reference)
	end

	def delete(conn, %{"node_id" => id, "id" => reference_id, "public_key" => public_key, "signature" => signature}) do
		node = Node.decode(id)
		reference_node = Node.decode(reference_id)
		calculation_opts = CalculationOpts.get_from_conn(conn)
		reference = Reference.new(node.path, reference_node.path)
		ReferenceVote.delete(Base.decode64!(public_key), Base.decode64!(signature), reference)
		reference = Reference.load(reference, calculation_opts)

		conn
		|> put_status(:created)
		|> render(Liquio.Web.ReferenceView, "show.json", reference: reference)
	end

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