defmodule Liquio.NodeView do
	use Liquio.Web, :view

	def results_color(node) do
		if node.choice_type == "probability" do
			if node.results == nil do
				"#ddd"
			else
				score = if Map.has_key?(node.results.by_keys, node.default_results_key) do node.results.by_keys[node.default_results_key].mean else nil end
				cond do
					score == nil -> "#ddd"
					score < 0.25 -> "rgb(255, 164, 164)"
					score < 0.75 -> "rgb(249, 226, 110)"
					true -> "rgb(140, 232, 140)"
				end
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
			:results => node.results,
			:contributions => node.contributions |> Enum.map(fn(contribution) ->
				%{
					:datetime => Timex.format!(contribution.datetime, "{ISO:Basic}"),
					:choice => contribution.choice,
					:voting_power => contribution.voting_power,
					:identity_id => contribution.identity.id
				}
			end)
		}
	end
end