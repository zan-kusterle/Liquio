defmodule Liquio.HtmlPollView do
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

	def chart_svg_polyline(points) do
		Enum.map_join(Enum.zip([nil] ++ points, points), " ", fn({previous_point, point}) ->
			if point == nil do
				""
			else
				(if previous_point == nil do "M" else "L" end) <>
				(point |> to_svg_point |> Tuple.to_list |> Enum.join(","))
			end
		end)
	end

	def svg_x(x) do
		svg_x(x, 0)
	end

	def svg_x(x, min_offset) do
		width = 1060
		margin = 15
		sx = round(x * (1060 - 2 * margin) + margin)
		min(width - min_offset, max(min_offset, sx))
	end

	def svg_y(y) do
		height = 200
		margin = 15
		round((1 - y) * (height - 2 * margin) + margin)
	end

	def to_svg_point({x, y}) do
		{round(x * 1180 + 30), round((1 - y) * 100 + 10)}
	end
end
