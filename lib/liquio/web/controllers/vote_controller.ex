defmodule Liquio.Web.VoteController do
	use Liquio.Web, :controller

	action_fallback Liquio.Web.FallbackController
	
	with_params(%{
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:user => {Plugs.CurrentUser, [require: true]}
	},
	def create(conn, %{:node => node, :user => user, "choice" => choice, "unit" => unit_value, "at_date" => at_date_string}) do
		at_date = case Timex.parse(at_date_string, "{YYYY}-{0M}-{0D}") do
			{:ok, x} -> x
			{:err, _} -> Timex.today()
		end
		calculation_opts = CalculationOpts.get_from_conn(conn)

		VoteRepo.set(user, node, Vote.decode_unit!(unit_value), at_date, get_choice(choice))
		if MapSet.member?(calculation_opts.trust_metric_ids, to_string(user.id)) do
			{:info, "Your vote is now live."}
		else
			{:error, "Your vote is now live, but because you're not in trust metric it will not be counted. Get others to trust your identity by sharing it's URL to get into trust metric or change it in preferences."}
		end

		calculation_opts = Map.put(calculation_opts, :datetime, Timex.now)
		conn
		|> put_status(:created)
		|> put_resp_header("location", node_path(conn, :show, Enum.join(node.path, "_")))
		|> render(Liquio.Web.NodeView, "show.json", node: NodeRepo.load(node, calculation_opts, user))
	end)

	with_params(%{
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:user => {Plugs.CurrentUser, [require: true]}
	},
	def delete(conn, %{:node => node, :user => user, "unit" => unit_value, "at_date" => at_date_string}) do
		at_date = case Timex.parse(at_date_string, "{YYYY}-{0M}-{0D}") do
			{:ok, x} -> x
			{:err, _} -> Timex.today()
		end
		VoteRepo.delete(user, node, Vote.decode_unit!(unit_value), at_date)

		calculation_opts = CalculationOpts.get_from_conn(conn)
		conn
		|> put_status(:created)
		|> put_resp_header("location", node_path(conn, :show, node.path |> Enum.join("/")))
		|> render(Liquio.Web.NodeView, "show.json", node: NodeRepo.load(node, calculation_opts, user))
	end)

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
