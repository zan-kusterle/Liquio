defmodule Liquio.Reference do
	alias Liquio.Reference
	
	@enforce_keys [:path, :reference_path, :results]
	defstruct [:path, :reference_path, :results]

	def new(path, reference_path) do
		%Liquio.Reference{path: path, reference_path: reference_path, results: %{:relevance => 0.81}}
	end

	def decode(key, reference_key) do
		%Reference{
			path: key |> String.trim(" ") |> String.split("/"),
			reference_path: reference_key |> String.trim(" ") |> String.split("/"),
			results: %{:relevance => 0.81}
		}
	end

	def group_key(reference) do
		"#{Enum.join(reference.path, "/")} -> #{Enum.join(reference.reference_path, "/")}" |> String.downcase
	end
end
