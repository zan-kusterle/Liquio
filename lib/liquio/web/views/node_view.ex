defmodule Liquio.Web.NodeView do
	use Liquio.Web, :view

	def render("index.json", %{nodes: nodes}) do
		%{data: render_many(nodes, Liquio.Web.NodeView, "node.json")}
	end

	def render("show.json", %{node: node}) do
		%{data: render_one(node, Liquio.Web.NodeView, "node.json")}
	end

	def render("node.json", %{node: node}) do
		%{
			:path => node.path,
			:units => if Map.has_key?(node, :results) do
				node.results |> Enum.map(fn({unit_value, unit_results}) ->
					unit = Liquio.Vote.decode_unit!(unit_value)

					concrete_results = if unit.type == :spectrum do unit_results.spectrum else unit_results.quantity end
					concrete_results = concrete_results |> Map.put(:contributions, render_many(concrete_results.contributions, Liquio.Web.NodeView, "vote.json"))

					unit = unit
					|> Map.put(:type, to_string(unit.type))
					|> Map.put(:results, concrete_results)
					{unit.key, unit |> Map.drop([:key])}
				end) |> Enum.into(%{})
			else
				%{}
			end,
			:own_contribution => if Map.get(node, :own_contribution) do render("vote.json", %{node: node.own_contribution}) else nil end,
			:references => if Map.has_key?(node, :references) do render_many(node.references, Liquio.Web.NodeView, "node.json") else nil end,
			:inverse_references => if Map.has_key?(node, :inverse_references) do render_many(node.inverse_references, Liquio.Web.NodeView, "node.json") else nil end,
			:calculation_opts => Map.get(node, :calculation_opts)
		}
	end

	def render("reference.json", %{node: reference}) do
		%{
			node: render("node.json", %{node: reference.node}) |> Map.drop([:calculation_opts]),
			referencing_node: render("node.json", %{node: reference.reference_node}) |> Map.drop([:calculation_opts]),
			results: reference.results
		}
	end

	def render("vote.json", %{node: vote}) do
		%{
			:identity_username => vote.identity.username,
			:unit => Map.get(vote, :unit, "Score"),
			:at_date => Timex.format!(vote.at_date, "{ISO:Extended}"),
			:datetime => Timex.format!(vote.datetime, "{ISO:Extended}"),
			:choice => vote.choice,
			:voting_power => Map.get(vote, :voting_power),
			:weight => Map.get(vote, :weight)
		}
	end
end