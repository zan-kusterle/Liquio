defmodule Liquio.Node do
	alias Liquio.Node
	
	@enforce_keys [:path]
	defstruct [:path]

	def decode(key) do
		%Node{
			path: key |> String.trim(" ") |> String.split("/")
		}
	end

	def group_key(%{:path => path}) do
		path |> Enum.join("/") |> String.downcase
	end
end
