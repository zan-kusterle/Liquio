defmodule Democracy.HtmlPollView do
	use Democracy.Web, :view

	def score_color(score) do
		cond do
			score < 0.5 -> "rgb(255, 164, 164)"
			score < 0.75 -> "rgb(249, 226, 110)"
			true -> "rgb(140, 232, 140)"
		end
	end

	def chart_svg_polyline(results_with_datetime) do
		count = Enum.count(results_with_datetime)
		Enum.map_join(results_with_datetime, " ", fn({index, datetime, results}) ->
			ratio = index / (count - 1)
			x = 20 + 1200 * ratio
			y = 120 * (1 - results.mean)
			"#{x},#{y}"
		end)
	end
end
