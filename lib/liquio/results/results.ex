defmodule Liquio.Results do
	alias Liquio.{Node, CalculateResults, Repo}

	def from_vote(vote) when is_nil(vote) do nil end
	def from_vote(vote) do
		contribution = vote
		|> Map.put(:voting_power, 0.0)
		|> Repo.preload([:identity])
		
		%{
			:spectrum => from_contributions([contribution], Timex.now, 1, true),
			:quantity => from_contributions([contribution], Timex.now, 1, false)
		}
	end

	def from_votes(votes, inverse_delegations, calculation_opts = %{:datetime => datetime, :trust_metric_ids => trust_metric_ids, :topics => topics}) do
		contributions = CalculateResults.calculate(votes, inverse_delegations, trust_metric_ids, topics) |> Repo.preload([:identity])

		probability_votes = Enum.filter(votes, & &1.choice >= 0.0 and &1.choice <= 1.0)
		probability_contributions = CalculateResults.calculate(probability_votes, inverse_delegations, trust_metric_ids, topics) |> Repo.preload([:identity])

		%{
			:spectrum => from_contributions(probability_contributions, datetime, MapSet.size(calculation_opts.trust_metric_ids), true),
			:quantity => from_contributions(contributions, datetime, MapSet.size(calculation_opts.trust_metric_ids), false)
		}
	end

	def from_contributions(contributions, datetime, trust_metric_size, is_spectrum) do
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))
		vote_weight_halving_days = nil

		time_weighted_contributions =
			if vote_weight_halving_days == nil do
				contributions
			else
				contributions |> Enum.map(fn(contribution) ->
					Map.put(contribution, :voting_power, contribution.voting_power * moving_average_weight(contribution, datetime, vote_weight_halving_days))
				end)
			end

		embed_html = if is_spectrum do inline_results_spectrum(mean(time_weighted_contributions)) else inline_results_quantity(median(time_weighted_contributions)) end

		%{
			:total => total_power,
			:turnout_ratio => if trust_metric_size == 0 do 0 else total_power / trust_metric_size end,
			:count => Enum.count(contributions),
			:contributions => contributions,
			:embed => embed_html |> minify_html,
			:by_time => inline_results_by_time(nil) |> minify_html,
			:distribution => inline_results_distribution(nil) |> minify_html
		}
	end

	defp results_color(mean) do
		cond do
			mean == nil -> "#ddd"
			mean < 0.25 -> "rgb(255, 164, 164)"
			mean < 0.75 -> "rgb(249, 226, 110)"
			true -> "rgb(140, 232, 140)"
		end
	end

	defp minify_html(html) do
		html
		|> String.replace("\t", "")
		|> String.replace("\n", "")
		|> String.replace("\r", "\n")
		|> String.replace("\"", "'")
	end

	defp inline_results_spectrum(mean) do
		color = results_color(mean)
		text = if mean == nil do
			"?"
		else
			"#{round(mean * 100)}%"
		end

		"<div class=\"area\" style=\"background-color: #{color}\"><div class=\"bubble\"><p>#{text}</p></div></div>"
	end

	defp inline_results_quantity(mean) do
		text = if mean == nil do
			"?"
		else
			"#{round(mean)}"
		end

		"<div class=\"area\" style=\"background-color: #ddd\"><div class=\"bubble\"><p>#{text}</p></div></div>"
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

	defp mean(contributions) do
		total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))
		total_score = Enum.sum(Enum.map(contributions, fn(contribution) ->
			contribution.choice * contribution.voting_power
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