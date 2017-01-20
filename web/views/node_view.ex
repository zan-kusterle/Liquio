defmodule Liquio.NodeView do
	use Liquio.Web, :view

	def results_color(node) do
		if node.choice_type == "probability" do
			if node.results == nil do
				"#ddd"
			else
				score = if Map.has_key?(node.results.by_keys, "main") do node.results.by_keys["main"].mean else nil end
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
end