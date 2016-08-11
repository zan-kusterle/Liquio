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

	def chart_svg_polyline(points) do
		Enum.map_join(Enum.zip([nil] ++ points, points), " ", fn({previous_point, point}) ->
			if point == nil do
				""
			else
				{x, y} = point
				d = "#{round(x * 1200 + 20)},#{round((1 - y) * 118 + 1)}"
				if previous_point == nil do
					"M" <> d
				else
					"L" <> d
				end
			end
		end)
	end
end
