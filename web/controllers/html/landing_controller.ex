defmodule Liquio.LandingController do
	use Liquio.Web, :controller

	plug :put_layout, "landing.html"

	def index(conn, _params) do
		calculate_opts = get_calculation_opts_from_conn(conn)
		identity = Guardian.Plug.current_resource(conn)
		examples = [
			%{
				poll: Poll.force_get("probability", "genetically modified foods are dangerous", ["science", "biology", "gmo"])
				|> Map.put(:fa_icon, "leaf"),
				references: []
			},
			%{
				poll: Poll.force_get("quantity", "number of refugees EU should let inside", ["politics", "eu", "refugees"])
				|> Map.put(:fa_icon, "question"),
				references: []
			},
			%{
				poll: Poll.force_get("quantity", "year when we will have artificial general intelligence", ["science", "artificial intelligence"])
				|> Map.put(:fa_icon, "bolt"),
				references: []
			},
			%{
				poll: Poll.force_get("probability", "global warming is caused by human activity", ["science", "nature", "global warming"])
				|> Map.put(:fa_icon, "sun-o"),
				references: [%{
					poll: Poll.force_get("time_quantity", "sea level in meters", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "global temperature in celcius", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "ocean temperature in celcius", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "global ice in cubic meters", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "acidity of the surface ocean waters", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("probability", "glaciers are retreating almost everywhere around the world", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("probability", "not enough global temperature historical data available to know the cause of global warming", ["science", "nature", "global warming"]),
					for_choice: 0.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "global ice volume in cubic meters", ["science", "nature", "global warming"]),
					for_choice: 0.0,
					references: []
				}, %{
					poll: Poll.force_get("probability", "climate models used to model global warming are proven to be unreliable", ["science", "nature", "global warming"]),
					for_choice: 0.0,
					references: []
				}]
			},
			%{
				poll: Poll.force_get("quantity", "additional tax revenue in USD if recreational cannabis becomes legal in California", ["california", "politics", "economics"])
				|> Map.put(:fa_icon, "bank"),
				references: []
			},
			%{
				poll: Poll.force_get("probability", "the theory of evolution is true", ["science", "biology", "evolution"])
				|> Map.put(:fa_icon, "hourglass-end"),
				references: []
			}			
		]
		polls = %{
			:not_the_best_idea => Poll.force_get("probability", "vanilla ice cream flavor rating", ["joke"])
		}
		if identity != nil and Application.get_env(:liquio, :admin_identity_ids) |> Enum.member?(identity.id) do
			approve_references(examples, identity)
		end
		examples = Enum.map(examples, fn(example) ->
			example.poll
			|> Map.put(:results, Result.calculate(example.poll, calculate_opts))
			|> Map.put(:num_references, Enum.count(example.references))
		end)
		|> Enum.sort(& &1.results.turnout_ratio + 0.1 * &1.num_references > &2.results.turnout_ratio + 0.1 * &2.num_references)

		render conn, "index.html", examples: examples, polls: polls
	end

	def approve_references(examples, identity) do
		Enum.flat_map(examples, fn(%{:poll => poll, :references => references}) ->
			Enum.each(references, &(cast_approve_vote(poll, &1, identity)))
			approve_references(references, identity)
		end)
	end

	def cast_approve_vote(poll, reference, identity) do
		reference = Reference.get(poll, reference.poll, reference.for_choice)
		|> Repo.preload([:approval_poll])

		current_vote = Vote.current_by(reference.approval_poll, identity)
		if current_vote == nil do
			Vote.set(reference.approval_poll, identity, 1.0)
		end
	end
end