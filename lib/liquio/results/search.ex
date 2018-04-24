defmodule Liquio.Search do
	alias Liquio.Node
	
	def query(%{:votes => votes, :reference_votes => reference_votes}, query) do
		titles = votes
		|> Enum.map(& &1.title)
		|> Enum.concat(Enum.map(reference_votes, & &1.title))
		|> Enum.concat(Enum.map(reference_votes, & &1.reference_title))

		query = query |> String.downcase |> String.trim

		result_titles = titles |> Enum.filter(fn(title) ->
			String.contains?(String.downcase(title), query)
		end)
		|> Enum.uniq_by(& String.downcase(&1))

		result_titles |> Enum.map(& Node.new(&1))
	end
end
