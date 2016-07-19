defmodule Democracy.NumberFormat do
	use Phoenix.HTML

	def number_format(x) do
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
		|> String.replace(".0", ""))  <> suffix
		raw(s)
	end

	def number_format_simple(x) do
		s = :erlang.float_to_binary(x, [:compact, { :decimals, 2 }])
		|> String.replace(".0", "")
		raw(s)
	end

	def for_choice_format(reference) do
		if reference.poll.choice_type == "probability" do
			case reference.for_choice do
				0.0 -> "Negative"
				1.0 -> "Positive"
				x -> number_format(x)
			end
		else
			number_format(reference.for_choice)
		end
		
	end
end