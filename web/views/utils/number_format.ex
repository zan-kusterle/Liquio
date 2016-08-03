defmodule Democracy.NumberFormat do
	use Phoenix.HTML

	def number_format(x) do
		raw(format_number(x))
	end

	def number_format_simple(x, decimals \\ 2) do
		s = :erlang.float_to_binary(x, [:compact, { :decimals, decimals }])
		|> String.trim_trailing(".0")
		raw(s)
	end

	def for_choice_format(for_choice, choice_type) do
		if choice_type == "probability" do
			case for_choice do
				0.0 -> raw('<span style="color: rgb(255, 97, 97);">NEGATIVE</span>')
				1.0 -> raw('<span style="color: rgb(111, 206, 111);">POSITIVE</span>')
				x -> raw("#{format_number(x * 100)}%")
			end
		else
			raw(format_number(for_choice))
		end
	end

	def score_format(score, choice_type) do
		if choice_type == "probability" do
			case score do
				0.0 -> raw('<span style="color: rgb(255, 97, 97);">FALSE</span>')
				1.0 -> raw('<span style="color: rgb(111, 206, 111);">TRUE</span>')
				x -> raw("#{format_number(x * 100)}%")
			end
		else
			raw(format_number(score))
		end
	end

	def score_format(score) do
		score_format(score, "probability")
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
			"#{format_greater_than_zero(base)} x 10<sup>#{round_simple(power, 0)}</sup>"
		else
			n = Float.floor(2 - log_x) + 1
			if n < 0 do
				n = 0
			end
			round_simple x, round(n)
		end
	end

	defp round_simple(x, decimals) do
		:erlang.float_to_binary(x, [:compact, { :decimals, decimals }]) |> String.trim_trailing(".0")
	end
end