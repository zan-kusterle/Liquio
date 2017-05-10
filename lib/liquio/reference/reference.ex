defmodule Liquio.Reference do
	alias Liquio.Reference
	
	@enforce_keys [:path, :reference_path, :results]
	defstruct [:path, :reference_path, :results]

	def new(path, reference_path) do
		%Liquio.Reference{path: path, reference_path: reference_path, results: nil}
	end

	def path_from_key(key) do
		key |> String.trim(" ") |> String.split("/")
	end

	def decode(key, reference_key) do
		%Reference{
			path: path_from_key(key),
			reference_path: path_from_key(reference_key),
			results: nil
		}
	end

	def group_key(reference) do
		"#{Enum.join(reference.path, "/") |> String.downcase} -> #{Enum.join(reference.reference_path, "/") |> String.downcase}" |> String.downcase
	end
end
