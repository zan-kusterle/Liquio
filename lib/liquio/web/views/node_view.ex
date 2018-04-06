defmodule Liquio.Web.NodeView do
	use Liquio.Web, :view

	@results_keys [:average, :count, :total, :turnout_ratio, :embeds, :contributions_by_identities]

	def render("index.json", %{nodes: nodes}) do
		%{data: render_many(nodes, Liquio.Web.NodeView, "node.json")}
	end

	def render("show.json", %{node: node}) do
		%{data: render_one(node, Liquio.Web.NodeView, "node.json")}
	end

	def render("node.json", %{node: node}) do
		%{
			:results => node.results
		}
	end

	"""
	def render("node.json", %{node: node}) do
		references = if Map.get(node, :references) do
			node.references |> Enum.map(fn(reference) ->
				reference_results = render_one(reference, Liquio.Web.ReferenceView, "results.json")

				reference_results = if Map.has_key?(reference, :for_choice_results) do
					for_choice = reference.for_choice_results.by_units
					|> Enum.map(fn({k, unit_results}) ->
						{k, unit_results.average}
					end)
					|> Enum.into(%{})
					
					reference_results
					|> Map.put(:for_choice, for_choice)
				else
					reference_results
				end

				render(Liquio.Web.NodeView, "node.json", %{node: reference.reference_node})
				|> Map.put(:reference_results, reference_results)
			end)
		else
			nil
		end

		inverse_references = if Map.get(node, :inverse_references) do
			node.inverse_references |> Enum.map(fn(reference) ->
				reference_results = render_one(reference, Liquio.Web.ReferenceView, "results.json")

				render(Liquio.Web.NodeView, "node.json", %{node: reference.node})
				|> Map.put(:reference_results, reference_results)
			end)
		else
			nil
		end

		first_path = node.path |> Enum.at(0)
		is_link = first_path != nil and (String.starts_with?(first_path, "http:") or String.starts_with?(first_path, "https:"))
		title = node.path |> Enum.join("/")
		title = if is_link do
			title |> String.replace("https:", "https://") |> String.replace("http:", "http://")
		else
			title |> String.replace("-", " ")
		end

		%{
			:results => render("results.json", %{node: Map.get(node, :results)}),
			:references => references,
			:inverse_references => inverse_references
		}
	end

	def render("results.json", %{node: results}) when results == nil do nil end
	def render("results.json", %{node: results}) do
		by_units = results.by_units |> Enum.map(fn({k, unit_results}) ->
			contributions_by_identities = unit_results.contributions_by_identities |> Enum.map(fn({k, data}) ->
				{k, %{
					:contributions => render_many(data.contributions, Liquio.Web.NodeView, "vote.json"),
					:embeds => data.embeds
				}}
			end) |> Enum.into(%{})

			unit_results = unit_results
			|> Map.take(@results_keys)
			|> Map.merge(unit_results.unit)
			|> Map.put(:contributions_by_identities, contributions_by_identities)


			{k, unit_results}
		end) |> Enum.into(%{})

		results
		|> Map.put(:by_units, by_units)
		|> Map.drop([:votes])
	end

	def render("vote.json", %{node: vote}) do
		%{
			:identity_username => vote.username,
			:unit => vote.unit,
			:at_date => Timex.format!(Map.get(vote, :at_date, vote.datetime), "{YYYY}-{0M}-{0D}"),
			:datetime => Timex.format!(vote.datetime, "{ISO:Extended:Z}"),
			:choice => vote.choice,
			:voting_power => Map.get(vote, :voting_power),
			:weight => Map.get(vote, :weight),
			:embeds => Map.get(vote, :embeds)
		}
	end


	@results_keys [:average, :count, :total, :turnout_ratio, :embeds, :contributions_by_identities]
	def render("reference.json", %{reference: reference}) do
		%{
			node: render_one(reference.node, Liquio.Web.NodeView, "node.json") |> Map.drop([:calculation_opts]),
			referencing_node: render_one(reference.reference_node, Liquio.Web.NodeView, "node.json") |> Map.drop([:calculation_opts]),
			results: render("results.json", %{:reference => reference})
		}
	end

	def render("results.json", %{:reference => %{:results => results}}) do
		results = if Map.has_key?(results, :contributions_by_identities) do
			contributions_by_identities = results.contributions_by_identities |> Enum.map(fn({k, data}) ->
				{k, %{
					:contributions => render_many(data.contributions, Liquio.Web.ReferenceView, "reference_vote.json"),
					:embeds => data.embeds
				}}
			end) |> Enum.into(%{})

			Map.put(results, :contributions_by_identities, contributions_by_identities)
		else
			results
		end

		results
		|> Map.take(@results_keys)
		|> Map.put(:contributions, render_many(Map.get(results, :latest_contributions, []), Liquio.Web.ReferenceView, "reference_vote.json"))
	end
	
	def render("reference_vote.json", %{reference: vote}) do
		%{
			:identity_username => vote.username,
			:datetime => Timex.format!(vote.datetime, "{ISO:Extended:Z}"),
			:relevance => vote.relevance,
			:voting_power => Map.get(vote, :voting_power),
			:weight => Map.get(vote, :weight),
			:embeds => Map.get(vote, :embeds)
		}
	end
	"""
end