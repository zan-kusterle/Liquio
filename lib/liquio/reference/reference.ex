defmodule Liquio.Reference do
	alias Liquio.Reference
	
	@enforce_keys [:path, :reference_path, :results]
	defstruct [:path, :reference_path, :results]

	def new(path, reference_path) do
		%Liquio.Reference{path: path, reference_path: reference_path, results: %{:relevance => 0.81}}
	end

	def path_from_key(key) do
		key |> String.trim(" ") |> String.split("/")
	end

	def decode(key, reference_key) do
		%Reference{
			path: path_from_key(key),
			reference_path: path_from_key(reference_key),
			results: %{:relevance => 0.81}
		}
	end

	def group_key(reference) do
		"#{Enum.join(reference.path, "/")} -> #{Enum.join(reference.reference_path, "/")}" |> String.downcase
	end
end
