defmodule Liquio.Web.ReferenceView do
	use Liquio.Web, :view

	@results_keys [:average, :count, :total, :turnout_ratio, :embeds, :contributions_by_identities]

	def render("index.json", %{references: references}) do
		%{data: render_many(references, Liquio.Web.ReferenceView, "reference.json")}
	end

	def render("show.json", %{reference: reference}) do
		%{data: render_one(reference, Liquio.Web.ReferenceView, "reference.json")}
	end

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
end