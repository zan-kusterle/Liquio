defmodule Liquio.Node do
	alias Liquio.Node
	alias Liquio.Average

	def new(title, unit) do
		new(title, nil, unit)
	end
	def new(title, anchor, unit) do
		new(title, anchor, unit, [])
	end
	def new(title, anchor, unit, comments) do
		%{
			:definition => %{
				:title => title,
				:anchor => anchor,
				:unit => unit,
				:comments => comments,
			},
			:data => %{
				:results => nil,
				:comments => nil,
				:references => nil,
				:inverse_references => nil
			}
		}
	end

	def add_comment(node, text) do
		Node.new(node.title, node.anchor, node.unit)
		|> Map.put(:definition, Map.put(node.definition, :comments, node.definition.comments ++ [text]))
	end

	def add_data(node, data) do
		Map.put(node, :data, Map.merge(node.data, data))
	end

	def load(node, data) do
		load(node, data, 1)
	end
	def load(
		node,
		data = %{
			:delegations => delegations,
			:votes => votes,
			:reference_votes => all_reference_votes
		},
		depth
	) do
		inverse_delegations = delegations |> Enum.map(&{&1.to_username, &1}) |> Enum.into(%{})

		node = if depth == 0 do
			node
		else
			votes = Enum.filter(votes, & compare_definition(&1, node.definition))

			results_votes = votes
			|> Enum.filter(& Enum.empty?(&1.comments))
			results_votes = if is_unit_spectrum(node.definition.unit) do
				Enum.filter(results_votes, &(&1.choice >= 0.0 and &1.choice <= 1.0))
			else
				results_votes
			end

			results = Liquio.Results.from_votes(results_votes, inverse_delegations)

			comments = votes
				|> Enum.filter(& Enum.count(&1.comments) == 1) # check if 1 more comment than node.definition.comments
				|> Enum.group_by(& Enum.at(&1.comments, 0))
				|> Enum.map(fn {comment, votes_for_comment} ->
					Node.add_comment(node, comment)
					|> Node.load(data, depth)
				end)

			Node.add_data(node, %{
				:results => results,
				:comments => comments
			})
		end

		node = if depth == 0 do
			node
		else
			references =
				all_reference_votes
				|> Enum.filter(& compare_definition(&1, node.definition) and not compare_definition(get_reference_definition(&1), node.definition))
				|> Enum.group_by(&slug(&1.reference_title))
				|> Enum.flat_map(fn {_key, votes} ->
					best_title = Average.mode(Enum.map(votes, & &1.reference_title))
					votes
					|> Enum.group_by(& &1.unit)
					|> Enum.map(fn {unit, unit_votes} ->
						Node.new(best_title, unit)
						|> Map.put(:reference_results, Liquio.Results.from_votes(unit_votes, inverse_delegations))
						|> Node.load(data, depth - 1)
					end)
				end)

			inverse_references =
				all_reference_votes
				|> Enum.filter(& compare_definition(get_reference_definition(&1), node.definition) and not compare_definition(&1, node.definition))
				|> Enum.group_by(&slug(&1.title))
				|> Enum.flat_map(fn {_key, votes} ->
					best_title = Average.mode(Enum.map(votes, & &1.title))
					votes
					|> Enum.group_by(& &1.unit)
					|> Enum.map(fn {unit, title_votes} ->
						Node.new(best_title, unit)
						|> Map.put(:reference_results, Liquio.Results.from_votes(title_votes, inverse_delegations))
						|> Node.load(data, depth - 1)
					end)
				end)

			Node.add_data(node, %{
				:references => references,
				:inverse_references => inverse_references
			})
		end

		node
	end

	def list_by_title(title, data, depth) do
		all_nodes = data.votes
		|> Enum.filter(& slug(&1.title) == slug(title))
		|> Enum.map(& Node.new(&1.title, &1.anchor, &1.unit))
		|> Enum.uniq_by(& &1.definition)

		all_nodes
		|> Enum.map(& Node.load(&1, data, depth))
	end

	defp get_reference_definition(vote) do
		%{
			:title => vote.reference_title,
			:anchor => vote.reference_anchor,
			:unit => vote.reference_unit,
			:comments => Map.get(vote, :reference_comments, [])
		}
	end

	defp compare_definition(a, b) do
		slug(a.title) == slug(b.title) and a.anchor == b.anchor and a.unit == b.unit and Enum.count(a.comments) == Enum.count(b.comments)
	end

	defp slug(x) do
		x |> String.replace(" ", "-") |> String.downcase()
	end

	defp is_unit_spectrum(unit_value) do
		String.contains?(unit_value, "-")
	end
end
