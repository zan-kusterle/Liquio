defmodule Liquio.NodeView do
		use Liquio.Web, :view

	def score_color(poll) do
		if poll.choice_type == "probability" do
			score = poll.results.mean
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

	def default_score_color() do
		"#ddd"
	end

	def svg_path(points) do
		Enum.map_join(Enum.zip([nil] ++ points, points), " ", fn({previous_point, point}) ->
			if point == nil do
				""
			else
				{x, y, _, _, _} = point
				(if previous_point == nil do "M" else "L" end) <> "#{svg_x x},#{svg_y y}"
			end
		end)
	end

	def svg_x(x) do
		width = 1060
		margin = 15
		round(x * (width - 2 * margin) + margin)
	end

	def svg_y(y) do
		height = 200
		margin = 15
		round((1 - y) * (height - 2 * margin) + margin)
	end
end