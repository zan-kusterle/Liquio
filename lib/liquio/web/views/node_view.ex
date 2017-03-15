defmodule Liquio.Web.NodeView do
	use Liquio.Web, :view

	def results_color(results, results_key) do
		if results.choice_type == "probability" or results_key == "relevance" do
			score = if Map.has_key?(results.by_keys, results_key) do results.by_keys[results_key].mean else nil end
			cond do
				score == nil -> "#ddd"
				score < 0.25 -> "rgb(255, 164, 164)"
				score < 0.75 -> "rgb(249, 226, 110)"
				true -> "rgb(140, 232, 140)"
			end
		else
			"#ddd"
		end
	end
	
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
			:key => String.trim(node.key, "_"),
			:reference_key => node.reference_key && String.trim(node.reference_key, "_"),
			:url_key => node.url_key,
			:results => if node.choice_type != nil or node.reference_key != nil do Map.get(node, :results) else nil end,
			:contributions => if node.choice_type != nil or node.reference_key != nil do Enum.map(Map.get(node, :contributions, []), & map_contribution(&1)) else [] end,
			:own_contribution => if Map.get(node, :own_contribution) do map_contribution(node.own_contribution) else nil end,
			:references => if Map.has_key?(node, :references) do render_many(node.references |> Enum.filter(& &1.choice_type == nil or &1.results.count > 0) , Liquio.Web.NodeView, "reference.json") else nil end,
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

	def map_contribution(contribution) do
		contribution
		|> Map.put(:identity_username, contribution.identity.username)
		|> Map.put(:datetime, Timex.format!(contribution.datetime, "{ISO:Extended}"))
		|> Map.take([:identity_username, :choice, :choice_type, :datetime, :title, :turnout_ratio, :voting_power, :weight, :results])
	end
end