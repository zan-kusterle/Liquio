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

		%{
			:path => node.path,
			:results => render("results.json", %{node: Map.get(node, :results)}),
			:references => references,
			:inverse_references => inverse_references,
			:calculation_opts => Map.get(node, :calculation_opts)
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
end