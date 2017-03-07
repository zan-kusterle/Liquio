defmodule Liquio.HtmlHelper do
	def minify(html) do
		html
		|> String.replace("\t", "")
		|> String.replace("\n", "")
		|> String.replace("\r", "\n")
		|> String.replace("<!DOCTYPE html>", "<!DOCTYPE html>\n")
	end
end