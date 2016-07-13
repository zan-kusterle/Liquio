defmodule Democracy.HtmlVoteView do
	use Democracy.Web, :view

	def number_format(x) do
		:erlang.float_to_binary(x, [:compact, { :decimals, 2 }])
		|> String.replace(".0", "")
	end
end