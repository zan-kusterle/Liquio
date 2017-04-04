defmodule Liquio.Node do
	alias Liquio.Node
	
	@enforce_keys [:path, :reference_path, :group_key, :unit]
	defstruct [:path, :reference_path, :group_key, :unit]

	def decode(key) do
		{path, unit} = decode_key(key)
		%Node{
			path: path,
			reference_path: nil,
			group_key: get_group_key(path, nil),
			unit: unit
		}
	end

	def decode_many(key) do
		nodes = key
		|> String.split("___")
		|> Enum.filter(& String.length(&1) > 0)
		|> Enum.map(& decode(&1))
		|> Enum.filter(& &1 != nil)
	end

	def put_title(node, title) do
		node
		|> Map.put(:title, title)
		|> Map.put(:key, get_key(title, node.choice_type))
	end

	def put_reference_key(node, reference_key) do
		{title, choice_type} = decode_key(reference_key)
		reference_key = if String.length(reference_key) > 0 do reference_key else nil end
		node
		|> Map.put(:reference_key, reference_key)
		|> Map.put(:reference_title, title)
		|> Map.put(:reference_choice_type, choice_type)
	end

	defp decode_key(key) do		
		clean_key = key |> String.replace("___", "") |> String.trim(" ")
		path = String.split(clean_key, "_")
		choice_type = if Enum.count(path) > 1 do
			if String.length(List.last(path)) == 0 do nil else List.last(path) end
		else
			nil
		end
		clean_path = if choice_type == nil do path else Enum.slice(path, 0..Enum.count(path) - 1) end

		clean_choice_type = cond do
			choice_type == nil -> nil
			String.downcase(choice_type) == "probability" -> :probability
			String.downcase(choice_type) == "quantity" -> :quantity
			true -> nil
		end

		{clean_path, clean_choice_type && to_string(clean_choice_type)}
	end
	
	defp get_key(title, choice_type) do
		"#{title |> String.replace(" ", "-")}_#{choice_type |> to_string |> String.replace("_", "-")}" |> String.trim("-")
	end

	def get_group_key(path, reference_path) do
		get_group_key(path, reference_path, "main")
	end
	def get_group_key(path, reference_path, filter_key) do
		[Enum.join(path, "_"), if reference_path do Enum.join(reference_path, "_") else nil end, filter_key]
		|> Enum.filter(& &1 != nil)
		|> Enum.join("___")
	end
end
