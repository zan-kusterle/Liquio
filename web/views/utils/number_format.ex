defmodule Democracy.NumberFormat do
	use Phoenix.HTML

	def number_format(x) do
		raw(format_number(x))
	end

	def number_format_simple(x) do
		s = :erlang.float_to_binary(x, [:compact, { :decimals, 2 }])
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
		x = x * 1.0
		{value, suffix} = cond do
			x > 999999999.999999 ->
				{x / 1000000000, " x 10<sup>9</sup>"}
			x > 999999.999999 ->
				{x / 1000000, " x 10<sup>6</sup>"}
			true ->
				{x, ""}
		end

		s = (:erlang.float_to_binary(value, [:compact, { :decimals, 2 }])
		|> String.trim_trailing(".0"))  <> suffix
	end
end