defmodule Liquio.NodeView do
	use Liquio.Web, :view

	def results_color(results, results_key) do
		if results.choice_type == "probability" do
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
		%{data: render_many(nodes, Liquio.NodeView, "node.json")}
	end

	def render("show.json", %{node: node}) do
		%{data: render_one(node, Liquio.NodeView, "node.json")}
	end

	def render("node.json", %{node: node}) do
		%{
			:title => node.title,
			:choice_type => node.choice_type,
			:key => node.key,
			:url_key => node.url_key,
			:results => if node.choice_type != nil do node.results else nil end,
			:contributions => if node.choice_type != nil do Enum.map(node.contributions, & map_contribution(&1)) else nil end,
			:own_contribution => if Map.get(node, :own_contribution) do map_contribution(node.own_contribution) else nil end,
			:embed_html => if node.choice_type != nil do node.embed else "" end,
			:references => render_many(Map.get(node, :references, []), Liquio.NodeView, "node.json"),
			:inverse_references => render_many(Map.get(node, :inverse_references, []), Liquio.NodeView, "node.json"),
			:reference_result => Map.get(node, :reference_result),
			:calculation_opts => node.calculation_opts
		}
	end

	def map_contribution(contribution) do
		contribution
		|> Map.put(:datetime, Timex.format!(contribution.datetime, "{ISO:Basic}"))
		|> Map.put(:identity, render_one(contribution.identity, Liquio.IdentityView, "identity.json"))
		|> Map.put(:embed_html, contribution.embed)
		|> Map.take([:choice, :choice_tyoe, :datetime, :embed_html, :identity, :title, :turnout_ratio, :voting_power, :weight, :results])
	end
end