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
			:results => if Map.has_key?(node, :results) do
				node.results
				|> Map.put(:contributions, Enum.map(node.results.contributions, & render("vote.json", %{vote: &1})))
			else
				nil
			end,
			:own_contribution => if Map.get(node, :own_contribution) do render("vote.json", %{vote: node.own_contribution}) else nil end,
			:references => if Map.has_key?(node, :references) do render_many(node.references |> Enum.filter(& &1.unit == nil or Map.has_key?(&1, :results) and &1.results.count > 0) , Liquio.Web.NodeView, "reference.json") else nil end,
			:inverse_references => if Map.has_key?(node, :inverse_references) do render_many(node.inverse_references, Liquio.Web.NodeView, "node.json") else nil end,
			:calculation_opts => Map.get(node, :calculation_opts)
		}
	end

	def render("reference.json", %{node: reference_node}) do
		r = render("node.json", %{node: reference_node})
		r = if Map.has_key?(reference_node, :reference_result) do
			Map.put(r, :reference_result, reference_node.reference_result)
		else
			r
		end
		r |> Map.drop([:calculation_opts])
	end

	def render("vote.json", %{vote: vote}) do
		%{
			:identity_username => vote.identity.username,
			:unit => Map.get(vote, :unit, "Score"),
			:is_probability => Map.get(vote, :is_probability, true),
			:filter_key => vote.filter_key,
			:at_date => Timex.format!(vote.at_date, "{ISO:Extended}"),
			:datetime => Timex.format!(vote.datetime, "{ISO:Extended}"),
			:choice => vote.choice,
			:voting_power => Map.get(vote, :voting_power),
			:weight => Map.get(vote, :weight)
		}
	end
end