defmodule Liquio.Node do
	alias Liquio.Node
	
	@enforce_keys [:choice_type, :key, :reference_key]
	defstruct [:title, :choice_type, :key, :reference_title, :reference_choice_type, :reference_key]

	def decode(key) do
		{title, choice_type} = decode_key(key)
		%Node{
			title: title,
			choice_type: choice_type,
			key: get_key(title, choice_type),
			reference_key: nil
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
			if String.length(Enum.at(path, 1)) == 0 do nil else Enum.at(path, 1) end
		else
			nil
		end
		choice_note = if Enum.count(path) > 2 do Enum.at(path, 2) else nil end

		{title, choice_type} = if choice_type == nil do
			{clean_key, nil}
		else
			clean_title = String.slice(clean_key, 0, String.length(clean_key) - String.length(to_string(choice_type))) |> String.trim("_") |> String.trim("-")
			{clean_title, choice_type |> String.downcase}
		end

		title = if String.starts_with?(clean_key, "http://") or String.starts_with?(clean_key, "https://") do
			title
		else
			title |> String.replace("-", " ")
		end

		{title, choice_type}
	end
	
	defp get_key(title, choice_type) do
		"#{title |> String.replace(" ", "-")}_#{choice_type |> to_string |> String.replace("_", "-")}" |> String.trim("-")
	end

	def choice_type_to_unit(choice_type) do
		units = Application.get_env(:liquio, :units)
		unit = if Map.has_key?(units, choice_type) do units[choice_type] else nil end
		{unit_type, unit_a, unit_b} = if unit do unit else {:probability, to_string(choice_type), nil} end
		{unit_type, unit_a, unit_b}
	end
end
