defmodule Liquio.Web.NodeView do
	use Liquio.Web, :view

	@results_keys [:average, :count, :total, :turnout_ratio, :embeds]

	def render("index.json", %{nodes: nodes}) do
		%{data: render_many(nodes, Liquio.Web.NodeView, "node.json")}
	end

	def render("show.json", %{node: node}) do
		%{data: render_one(node, Liquio.Web.NodeView, "node.json")}
	end

	def render("node.json", %{node: node}) do
		references =  if Map.has_key?(node, :references) do
			node.references |> Enum.map(fn(%{:results => results, :reference_node => reference_node}) ->
				results = results
				|> Map.take(@results_keys)
				|> Map.put(:contributions, render_many(results.latest_contributions, Liquio.Web.NodeView, "reference_vote.json"))

				render(Liquio.Web.NodeView, "node.json", %{node: reference_node})
				|> Map.put(:reference_results, results)
			end)
		else
			nil
		end

		inverse_references =  if Map.has_key?(node, :inverse_references) do
			node.inverse_references |> Enum.map(fn(%{:results => results, :node => reference_node}) ->
				results = results
				|> Map.take(@results_keys)
				|> Map.put(:contributions, render_many(results.latest_contributions, Liquio.Web.NodeView, "reference_vote.json"))
				render(Liquio.Web.NodeView, "node.json", %{node: reference_node})
				|> Map.put(:reference_results, results)
			end)
		else
			nil
		end

		%{
			:path => node.path,
			:results => render("results.json", %{node: Map.get(node, :results)}),
			:own_results => render("results.json", %{is_own: true, node: if Map.has_key?(node, :own_results) do node.own_results else nil end}),
			:references => references,
			:inverse_references => inverse_references,
			:calculation_opts => Map.get(node, :calculation_opts)
		}
	end

	def render("reference.json", %{node: reference}) do
		%{
			node: render("node.json", %{node: reference.node}) |> Map.drop([:calculation_opts]),
			referencing_node: render("node.json", %{node: reference.reference_node}) |> Map.drop([:calculation_opts]),
			results: reference.results
				|> Map.take(@results_keys)
				|> Map.put(:contributions, render_many(reference.results.latest_contributions, Liquio.Web.NodeView, "reference_vote.json")),
			own_results: if reference.own_results do
				reference.own_results
				|> Map.take(@results_keys)
				|> Map.put(:contributions, render_many(reference.own_results.latest_contributions, Liquio.Web.NodeView, "reference_vote.json"))
			else
				nil
			end
		}
	end

	def render("results.json", %{node: results}) when results == nil do nil end
	def render("results.json", args = %{node: results}) do
		is_own = Map.get(args, :is_own, false)
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

			unit_results = if is_own do
				own_contributions = contributions_by_identities |> Map.values |> List.first
				unit_results |> Map.put(:own_contributions, own_contributions)
			else
				unit_results |> Map.put(:contributions_by_identities, contributions_by_identities)
			end
			

			{k, unit_results}
		end) |> Enum.into(%{})

		results
		|> Map.put(:by_units, by_units)
	end

	def render("vote.json", %{node: vote}) do
		%{
			:identity_username => vote.identity.username,
			:unit => vote.unit,
			:at_date => Timex.format!(Map.get(vote, :at_date, vote.datetime), "{YYYY}-{0M}-{0D}"),
			:datetime => Timex.format!(vote.datetime, "{ISO:Extended}"),
			:choice => vote.choice,
			:voting_power => Map.get(vote, :voting_power),
			:weight => Map.get(vote, :weight),
			:embeds => Map.get(vote, :embeds)
		}
	end

	def render("reference_vote.json", %{node: vote}) do
		%{
			:identity_username => vote.identity.username,
			:datetime => Timex.format!(vote.datetime, "{ISO:Extended}"),
			:relevance => vote.relevance,
			:voting_power => Map.get(vote, :voting_power),
			:weight => Map.get(vote, :weight),
			:embeds => Map.get(vote, :embeds)
		}
	end
end