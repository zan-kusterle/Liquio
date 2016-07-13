defmodule Democracy.NumberFormat do
	use Phoenix.HTML

	def number_format(x) do
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
end