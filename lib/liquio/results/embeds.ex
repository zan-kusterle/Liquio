defmodule Liquio.ResultsEmbeds do
	def inline_results_spectrum(mean, unit) do
		line_offset = 0.22

		line = "<line vector-effect=\"non-scaling-stroke\" x1=\"#{ svg_x line_offset }\" y1=\"#{ svg_y 0.5 }\" x2=\"#{ svg_x 1 - line_offset }\" y2=\"#{ svg_y 0.5 }\" style=\"stroke: #ccc; stroke-width: 3;\"></line>"
		point = if mean do
			x = svg_x(mean * (1 - 2 * line_offset) + line_offset)
			"<text text-anchor=\"middle\" x=\"#{ x + 8 }\" y=\"65\" font-family=\"Helvetica\" font-size=\"36\">#{round(mean * 100)}%</text>" <>
			"<line vector-effect=\"non-scaling-stroke\" x1=\"#{ x }\" y1=\"#{ svg_y 0.4 }\" x2=\"#{ x }\" y2=\"#{ svg_y 0.6 }\" style=\"stroke: #555; stroke-width: 2;\"></line>"
		else
			""
		end
		negative_text = "<text text-anchor=\"end\" alignment-baseline=\"middle\" x=\"#{svg_x line_offset - 0.03 }\" y=\"#{ svg_y 0.5 }\" font-family=\"Helvetica\" font-size=\"22\" style=\"text-transform: uppercase;\">#{unit.negative}</text>"
		positive_text = "<text text-anchor=\"start\" alignment-baseline=\"middle\" x=\"#{ svg_x 1 - line_offset + 0.03 }\" y=\"#{ svg_y 0.5 }\" font-family=\"Helvetica\" font-size=\"22\" style=\"text-transform: uppercase;\">#{unit.positive}</text>"

		"<svg viewBox=\"0 0 800 200\" class=\"chart\" width=\"100%\" height=\"100%\">#{positive_text}#{line}#{point}#{negative_text}</svg>"
	end

	def inline_results_quantity(mean, unit) do
		color = if unit.type == :spectrum do results_color(mean) else "#ddd" end

		text = if mean == nil do
			"?"
		else
			if unit.type == :spectrum do
				"#{round(mean * 100)}%"
			else
				unit_text = if unit.measurement == "Count" do "" else unit.unit || unit.measurement end
				"#{format_number(mean)} #{unit_text}"
			end
		end
		sub_text = if unit.type == :spectrum do String.downcase(unit.positive) else nil end

		rect = "<rect x=\"0\" y=\"0\" width=\"800\" height=\"200\" style=\"fill: #{color};\" />"
		text = "<text text-anchor=\"middle\" alignment-baseline=\"middle\" x=\"400\" y=\"108\" font-family=\"Helvetica\" font-size=\"96\">#{text}</text>"
		sub_text = if sub_text do
			"<text text-anchor=\"middle\" alignment-baseline=\"middle\" x=\"400\" y=\"160\" font-family=\"Helvetica\" font-size=\"28\" fill=\"#222\" font-weight=\"bold\">#{sub_text}</text>"
		else
			""
		end
		"<svg viewBox=\"0 0 800 200\" class=\"chart\" width=\"100%\" height=\"100%\">#{rect}#{text}</svg>"
	end

	def inline_results_by_time(contributions, _) when length(contributions) < 2 do nil end
	def inline_results_by_time(contributions, aggregator) do
		from_date = List.first(contributions).at_date
		to_date = List.last(contributions).at_date

		num_months = Timex.diff(to_date, from_date, :months)
		contributions_by_identities = contributions |> Enum.group_by(& &1.identity.id)
		points = Enum.map(0..num_months, fn(i) ->
			current_date = Timex.shift(from_date, months: i)
			current_contributions = contributions_by_identities |> Enum.map(fn({_, contributions_for_identity}) ->
				contributions_for_identity
				|> Enum.filter(& Timex.compare(&1.at_date, current_date) <= 0)
				|> List.last
			end)
			|> Enum.filter(& &1 != nil)
			
			if Enum.count(current_contributions) > 0 do
				average = aggregator.(current_contributions)
				{current_date, average, 1.0}
			else
				nil
			end
		end)
		|> Enum.filter(& &1 != nil)

		svg_chart(points)
	end

	def inline_identity_contributions_by_time(identity_contributions) when length(identity_contributions) < 2 do nil end
	def inline_identity_contributions_by_time(identity_contributions) do
		points = identity_contributions |> Enum.map(fn(contribution) ->
			{contribution.at_date, contribution.choice, 1.0}
		end)

		svg_chart(points)
	end

	def inline_results_distribution(contributions, aggregator) do
		buckets = contributions |> Enum.group_by(& round(&1.choice * 10))
		rects = 0..10
		|> Enum.map(fn(index) -> {index, Map.get(buckets, index, [])} end)
		|> Enum.filter(fn({index, bucket_contributions}) -> Enum.count(bucket_contributions) > 0 end)
		|> Enum.map(fn({index, bucket_contributions}) ->
			average = aggregator.(bucket_contributions)
			"<rect x=\"#{svg_x(index / 10)}\" y=\"#{svg_y average}\" width=\"70\" height=\"#{svg_height average}\" style=\"fill:#ccc;\" />" <>
			"<text text-anchor=\"middle\" alignment-baseline=\"middle\" x=\"#{svg_x(index / 10) + 35}\" y=\"150\" font-family=\"Helvetica\" font-size=\"36\">#{index}</text>"
		end)
		"<svg viewBox=\"0 0 800 200\" class=\"chart\" width=\"100%\" height=\"100%\">#{Enum.join(rects, "")}</svg>"
	end

	defp svg_chart(points) do
		if Enum.count(points) >= 2 do
			{min_x, max_x} = Enum.min_max(Enum.map(points, & Timex.to_unix(elem(&1, 0))))
			{min_y, max_y} = Enum.min_max(Enum.map(points, & elem(&1, 1)))

			min_y = min(0, min_y)
			max_y = max(0, max_y)

			zero_y =
				cond do
					min_y < 0 and max_y > 0 ->
						-min_y / (max_y - min_y)
					max_y > 0 ->
						0
					min_y < 0 ->
						1
				end

			normalized_points = Enum.map(points, fn({x, y, w}) ->
				nx = if max_x == min_x do 0.5 else (Timex.to_unix(x) - min_x) / (max_x - min_x) end
				ny = if max_y == min_y do 0.5 else (y - min_y) / (max_y - min_y) end
				{nx, ny, w, x, y}
			end)
			
			line = "<line vector-effect=\"non-scaling-stroke\" x1=\"#{ svg_x 0 }\" y1=\"#{ svg_y zero_y }\" x2=\"#{ svg_x 1 }\" y2=\"#{ svg_y zero_y }\" style=\"stroke: #aaa; stroke-width: 2;\"></line>"
			path = "<path vector-effect=\"non-scaling-stroke\" fill=\"none\" stroke=\"#4aa5f3\" stroke-width=\"2\" d=\"#{ svg_path normalized_points }\"></path>"

			"<svg viewBox=\"0 0 800 200\" class=\"chart\" width=\"100%\" height=\"100%\" preserveAspectRatio=\"none\">#{line}#{path}</svg>"
		else
			nil
		end
	end
	
	defp svg_path(points) do
		Enum.map_join(Enum.zip([nil] ++ points, points), " ", fn({previous_point, point}) ->
			if point == nil do
				""
			else
				{x, y, _, _, _} = point
				(if previous_point == nil do "M" else "L" end) <> "#{svg_x x},#{svg_y y}"
			end
		end)
	end

	defp svg_x(x) do
		width = 800
		margin = 30
		round(x * (width - 2 * margin) + margin)
	end

	defp svg_y(y) do
		height = 200
		margin = 30
		round((1 - y) * (height - 2 * margin) + margin)
	end
	
	defp svg_height(ratio) do
		height = 200
		margin = 30
		round(ratio * (height - 2 * margin))
	end

	defp results_color(mean) do
		cond do
			mean == nil -> "#ddd"
			mean < 0.25 -> "rgb(255, 164, 164)"
			mean < 0.75 -> "rgb(249, 226, 110)"
			true -> "rgb(140, 232, 140)"
		end
	end

	defp number_format_simple(x, decimals \\ 2) do
		(x / 1)
		|> :erlang.float_to_binary([:compact, {:decimals, decimals}])
		|> String.trim_trailing(".0")
	end

	defp format_number(x) do
		abs_x = abs(x)
		if abs_x > 0 do
			s = format_greater_than_zero(abs_x)
			if x < 0 do "-#{s}" else s end
		else
			"0"
		end
	end

	defp ensure_rounding_sums_to(numbers, precision, target) do
		rounded = Enum.map(numbers, & Float.round(&1, precision))
		off = target - Enum.sum(rounded)
		numbers
		|> Enum.sort_by(& Float.round(&1, precision) - &1)
		|> Enum.map(& Float.round(&1, precision))
	end

	defp format_greater_than_zero(x) do
		log_x = :math.log10(x)
		if log_x >= 6 or log_x <= -4 do
			power = if x > 1 do
				Float.floor(log_x / 3) * 3
			else
				Float.floor(log_x)
			end
			power = round(power)
			base = x / :math.pow(10, power)
			multiplier_string = case power do
				6 -> "M"
				9 -> "B"
				_ -> "×10#{to_unicode_superscript(power)}"
			end
			"#{format_greater_than_zero(base)}#{multiplier_string}"
		else
			n = max(0, Float.floor(2 - log_x) + 1)
			round_simple x, round(n)
		end
	end

	defp round_simple(x, decimals) do
		(x / 1)
		|> :erlang.float_to_binary([:compact, {:decimals, decimals}])
		|> String.trim_trailing(".0")
	end

	defp to_unicode_superscript(n) do
		n
		|> to_string
		|> String.graphemes
		|> Enum.map(fn(digit) ->
			case digit do
				"0" -> 	"⁰"
				"1" -> 	"¹"
				"2" -> 	"²"
				"3" -> 	"³"
				"4" -> 	"⁴"
				"5" -> 	"⁵"
				"6" -> 	"⁶"
				"7" -> 	"⁷"
				"8" -> 	"⁸"
				"9" -> 	"⁹"
			end
		end)
	end

	defp minify_html(html) do
		html
		|> String.replace("\t", "")
		|> String.replace("\n", "")
		|> String.replace("\r", "\n")
		|> String.replace("\"", "'")
	end
end