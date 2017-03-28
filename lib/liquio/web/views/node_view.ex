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
			:title => node.title,
			:choice_type => node.choice_type,
			:key => node.key,
			:unit_type => Map.get(node, :unit_type),
			:unit_a => Map.get(node, :unit_a),
			:unit_b => Map.get(node, :unit_b),
			:reference_title => node.reference_title,
			:reference_choice_type => node.reference_choice_type,
			:reference_key => node.reference_key,
			:results => if node.choice_type != nil or node.reference_key != nil and Map.has_key?(node, :results) do
				node.results
				|> Map.put(:contributions, Enum.map(node.results.contributions, & render("vote.json", %{vote: &1})))
			else
				nil
			end,
			:own_contribution => if Map.get(node, :own_contribution) do render("vote.json", %{vote: node.own_contribution}) else nil end,
			:references => if Map.has_key?(node, :references) do render_many(node.references |> Enum.filter(& &1.choice_type == nil or Map.has_key?(&1, :results) and &1.results.count > 0) , Liquio.Web.NodeView, "reference.json") else nil end,
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
			:title => vote.title,
			:choice_type => vote.choice_type,
			:reference_title => vote.reference_title,
			:reference_choice_type => vote.reference_choice_type,
			:filter_key => vote.filter_key,
			:at_date => Timex.format!(vote.at_date, "{ISO:Extended}"),
			:datetime => Timex.format!(vote.datetime, "{ISO:Extended}"),
			:choice => vote.choice,
			:turnout_ratio => Map.get(vote, :turnout_ratio),
			:turnout_ratio => Map.get(vote, :voting_power)
		}
	end
end