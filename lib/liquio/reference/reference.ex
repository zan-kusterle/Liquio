defmodule Liquio.Reference do
	alias Liquio.Reference
	
	@enforce_keys [:path, :reference_path, :results]
	defstruct [:path, :reference_path, :results]

	def decode(key, reference_key) do
		%Reference{
			path: key |> String.trim(" ") |> String.split("/"),
			reference_path: reference_key |> String.trim(" ") |> String.split("/"),
			results: %{:relevance => 0.81}
		}
	end
end
