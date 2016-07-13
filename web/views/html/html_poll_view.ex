defmodule Democracy.HtmlPollView do
	use Democracy.Web, :view

	def score_color(poll) do
		if poll.choice_type == "probability" do
			score = poll.results.mean
			cond do
				score < 0.5 -> "rgb(255, 164, 164)"
				score < 0.75 -> "rgb(249, 226, 110)"
				true -> "rgb(140, 232, 140)"
			end
		else
			"#ddd"
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

	def number_format(x) do
		{value, suffix} = cond do
			x > 999999999.999999 ->
				{x / 1000000000, " x 10<sup>9</sup>"}
			x > 999999.999999 ->
				{x / 1000000, " x 10<sup>6</sup>"}
			true ->
				{x, ""}
		end

		(:erlang.float_to_binary(value, [:compact, { :decimals, 2 }])
		|> String.replace(".0", ""))  <> suffix
	end
end
