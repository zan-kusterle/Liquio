defmodule Liquio.Web.NodeController do
	use Liquio.Web, :controller
	
	def index(conn, _params) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		conn
		|> render("show.json", node: Node.all(calculation_opts))
	end

	def search(conn, %{"id" => query}) do
		calculation_opts = CalculationOpts.get_from_conn(conn)
		conn
		|> render("show.json", node: Node.search(query, calculation_opts))
	end

	def show(conn, %{"id" => id}) do
		slug = fn(x) ->
			x |> String.replace(" ", "-") |> String.downcase
		end

		case Liquio.GetData.get(nil, ["xszztdkfpyptpyzgd"]) do
			{:ok, data} ->
				votes = data.votes |> Enum.filter(& slug.(&1.title) === slug.(id))
				inverse_delegations = data.delegations |> Enum.map(& {&1.to_username, &1}) |> Enum.into(%{})
				results = Liquio.Results.from_votes(data.votes, inverse_delegations)
				IO.inspect results

				node = %{
					:results => results,
					:references => [],
					:inverse_references => []
				}

				conn
				|> render("show.json", node: node)
			{:error, message} ->
				conn
				|> render("show.json", node: nil)
		end

		node = Node.decode(id)
		calculation_opts = CalculationOpts.get_from_conn(conn)
	end

	def update(conn, %{"id" => id, "public_key" => public_key, "choice" => choice, "unit" => unit_value, "at_date" => at_date_string, "signature" => signature}) do
		node = Node.decode(id)
		at_date = case Timex.parse(at_date_string, "{YYYY}-{0M}-{0D}") do
			{:ok, x} -> x
			{:err, _} -> Timex.today()
		end
		calculation_opts = CalculationOpts.get_from_conn(conn)

		Vote.set(node, Base.decode64!(public_key), Base.decode64!(signature), Vote.decode_unit!(unit_value), at_date, get_choice(choice))

		calculation_opts = Map.put(calculation_opts, :datetime, Timex.now)
		conn
		|> put_status(:created)
		|> put_resp_header("location", node_path(conn, :show, Enum.join(node.path, "_")))
		|> render(Liquio.Web.NodeView, "show.json", node: Node.load(node, calculation_opts))
	end

	def delete(conn, %{"id" => id, "public_key" => public_key, "unit" => unit_value, "at_date" => at_date_string, "signature" => signature}) do
		node = Node.decode(id)
		at_date = case Timex.parse(at_date_string, "{YYYY}-{0M}-{0D}") do
			{:ok, x} -> x
			{:err, _} -> Timex.today()
		end
		Vote.delete(node, Base.decode64!(public_key), Base.decode64!(signature), Vote.decode_unit!(unit_value), at_date)

		calculation_opts = CalculationOpts.get_from_conn(conn)
		conn
		|> put_status(:created)
		|> put_resp_header("location", node_path(conn, :show, node.path |> Enum.join("/")))
		|> render(Liquio.Web.NodeView, "show.json", node: Node.load(node, calculation_opts))
	end

	defp get_choice(v) do
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
