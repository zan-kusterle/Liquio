defmodule Liquio.NumberFormat do
	use Phoenix.HTML

	def number_format(x) do
		raw(format_number(x))
	end

	def number_format_simple(x, decimals \\ 2) do
		(x / 1)
		|> :erlang.float_to_binary([:compact, {:decimals, decimals}])
		|> String.trim_trailing(".0")
	end

	def format_number(x) do
		abs_x = abs(x)
		if abs_x > 0 do
			s = format_greater_than_zero(abs_x)
			if x < 0 do "-#{s}" else s end
		else
			"0"
		end
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
end