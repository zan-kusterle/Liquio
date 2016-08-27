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

	def to_svg_point({x, y}) do
		{round(x * 1180 + 30), round((1 - y) * 100 + 10)}
	end
end
