defmodule Liquio.Node do
	alias Liquio.Node
	alias Liquio.Average

	def new(title) do
		%{
			:key => slug(title),
			:title => title,
			:results => %{},
			:references => [],
			:inverse_references => []
		}
	end

	def load(node, data) do
		load(node, data, 1)
	end

	def load(node, _data, depth) when depth === 0 do
		node
	end

	def load(node, data = %{:delegations => delegations, :votes => votes, :reference_votes => all_reference_votes}, depth) do
		inverse_delegations = delegations |> Enum.map(& {&1.to_username, &1}) |> Enum.into(%{})

		votes = votes |> Enum.filter(& slug(&1.title) === node.key)

		results_by_units = votes
		|> Enum.group_by(& &1.unit)
		|> Enum.map(fn({unit_value, votes_for_unit}) ->
			is_spectrum = false
			votes_for_unit = if is_spectrum do
				Enum.filter(votes_for_unit, & &1.choice >= 0.0 and &1.choice <= 1.0)
			else
				votes_for_unit
			end

			{unit_value, Liquio.Results.from_votes(votes_for_unit, inverse_delegations)}
		end)
		|> Enum.into(%{})

		reference_votes = all_reference_votes |> Enum.filter(fn(vote) ->
			key = slug(vote.title)
			key === node.key or String.starts_with?(key, "#{String.trim_trailing(node.key, "/")}/")
		end)
		references = reference_votes
		|> Enum.group_by(& slug(&1.reference_title))
		|> Enum.flat_map(fn({_key, votes}) ->
			votes
			|> Enum.group_by(& slug(&1.title))
			|> Enum.map(fn({_title, title_votes}) ->
				Average.mode(Enum.map(title_votes, & &1.reference_title))
				|> Node.new
				|> Map.put(:referenced_by_title, Average.mode(Enum.map(title_votes, & &1.title)))
				|> Map.put(:reference_results, Liquio.Results.from_votes(title_votes, inverse_delegations))
				|> Node.load(data, depth - 1)
			end)
		end)

		inverse_reference_votes = all_reference_votes |> Enum.filter(fn(vote) ->
			key = slug(vote.reference_title)
			key === node.key or String.starts_with?(key, "#{String.trim_trailing(node.key, "/")}/")
		end)
		inverse_references = inverse_reference_votes
		|> Enum.group_by(& slug(&1.title))
		|> Enum.flat_map(fn({_key, votes}) ->
			votes
			|> Enum.group_by(& slug(&1.reference_title))
			|> Enum.map(fn({_title, title_votes}) ->
				Average.mode(Enum.map(title_votes, & &1.title))
				|> Node.new
				|> Map.put(:referencing_title, Average.mode(Enum.map(title_votes, & &1.reference_title)))
				|> Map.put(:reference_results, Liquio.Results.from_votes(title_votes, inverse_delegations))
				|> Node.load(data, depth - 1)
			end)
		end)

		node
		|> Map.put(:results, results_by_units)
		|> Map.put(:references, references)
		|> Map.put(:inverse_references, inverse_references)
	end

	defp slug(x) do
		x |> String.replace(" ", "-") |> String.downcase
	end
end