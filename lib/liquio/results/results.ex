defmodule Liquio.Results do
	alias Liquio.Node

	def from_contribution(contribution) do
		%{
			:total => 0.0,
			:turnout_ratio => 0.0,
			:count => 1,
			:mean => contribution.choice,
			:choice_type => contribution.choice_type,
			:contributions => [contribution]
		} |> load()
	end

	def from_contributions(contributions, %{:datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		choice_type = if Enum.empty?(contributions) do nil else Enum.at(contributions, 0).choice_type end
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))
		trust_metric_size = MapSet.size(trust_metric_ids)

		time_weighted_contributions =
			if vote_weight_halving_days == nil do
				contributions
			else
				contributions |> Enum.map(fn(contribution) ->
					Map.put(contribution, :voting_power, contribution.voting_power * moving_average_weight(contribution, datetime, vote_weight_halving_days))
				end)
			end

		%{
			:total => total_power,
			:turnout_ratio => if trust_metric_size == 0 do 0 else total_power / trust_metric_size end,
			:count => Enum.count(contributions),
			:mean => mean(time_weighted_contributions),
			:median => median(time_weighted_contributions),
			:choice_type => choice_type,
			:contributions => contributions
		} |> load()
	end

	defp load(results) do
		text = inline_results_value(results) |> minify_html
		color = results_color(results)
		
		results
		|> Map.put(:text, text)
		|> Map.put(:color, color)
		|> Map.put(:embed, "<div class=\"area\" style=\"background-color: #{color}\"><div class=\"bubble\"><p>#{text}</p></div></div>")
		|> Map.put(:by_time, inline_results_by_time(results) |> minify_html)
		|> Map.put(:distribution, inline_results_distribution(results) |> minify_html)
	end

	defp results_color(results) do
		if results.choice_type == :probability and results.count > 0 do
			cond do
				results.mean == nil -> "#ddd"
				results.mean < 0.25 -> "rgb(255, 164, 164)"
				results.mean < 0.75 -> "rgb(249, 226, 110)"
				true -> "rgb(140, 232, 140)"
			end
		else
			"#ddd"
		end
	end

	defp minify_html(html) do
		html
		|> String.replace("\t", "")
		|> String.replace("\n", "")
		|> String.replace("\r", "\n")
		|> String.replace("\"", "'")
	end

	defp inline_results_value(results) do		
		if results.mean == nil do
			"?"
		else
			if results.choice_type == :probability do
				"#{round(results.mean * 100)}%"
			else
				"#{round(results.mean)}"				
			end
		end
	end

	defp inline_results_by_time(results) do
		results_with_datetime = []

		points = results_with_datetime |> Enum.map(& {&1.datetime, &1.mean, &1.turnout_ratio})
		if Enum.count(points) >= 2 do
			#render(Liquio.Web.ComponentsView, "chart.html", points: points, tooltips: false)
			"?"
		else
			"?"
		end
	end

	defp inline_results_distribution(results) do
		""
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
			base = x / :math.pow(10, power)
			"#{format_greater_than_zero(base)} x 10#{to_unicode_superscript(round(power))}"
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

	def by_key(aggregations_by_key, key) do
		Map.get(aggregations_by_key, key, %{
			:mean => nil,
			:total => 0,
			:turnout_ratio => 0,
			:count => 0
		})
	end

	defp mean(contributions) do
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))
		total_score = Enum.sum(Enum.map(contributions, fn(contribution) ->
			contribution.default_value * contribution.voting_power
		end))
		if total_power > 0 do
			1.0 * total_score / total_power
		else
			nil
		end
	end

	defp median(contributions) do
		contributions = contributions |> Enum.sort(&(&1.choice > &2.choice))
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))
		if total_power > 0 do
			Enum.reduce_while(contributions, 0.0, fn(contribution, current_power) ->
				if current_power + contribution.voting_power > total_power / 2 do
					{:halt, 1.0 * contribution.choice}
				else
					{:cont, current_power + contribution.voting_power}
				end
			end)
		else
			nil
		end
	end

	defp moving_average_weight(contribution, reference_datetime, vote_weight_halving_days) do
		ct = contribution.datetime |> Timex.to_erl |> :calendar.datetime_to_gregorian_seconds
		rt = reference_datetime |> Timex.to_erl |> :calendar.datetime_to_gregorian_seconds
		delta_days = (rt - ct) / (24 * 3600)

		:math.pow(0.5, delta_days / vote_weight_halving_days)
	end
end