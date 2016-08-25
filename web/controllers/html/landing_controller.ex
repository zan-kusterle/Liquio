defmodule Liquio.LandingController do
	use Liquio.Web, :controller

	plug :put_layout, "landing.html"

	def index(conn, _params) do
		calculate_opts = get_calculation_opts_from_conn(conn)
		identity = Guardian.Plug.current_resource(conn)
		examples = [
			%{
				poll: Poll.force_get("probability", "global warming is caused by human activity", ["science", "nature", "global warming"]),
				references: [%{
					poll: Poll.force_get("quantity", "sea level rise since year 1900 in centimeters", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("quantity", "difference in sea level from year 2000 until year 2050 in centimeters", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}]
			},
			%{
				poll: Poll.force_get("probability", "Donald Trump is wrong that the USA is the highest taxed nation in the world", ["politics", "usa", "donald trump"]),
				references: [%{
					poll: Poll.force_get("probability", "Donald Trump said the USA is the highest taxed nation in the world", ["politics", "usa", "donald trump"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("quantity", "median tax rate in the USA", ["economics", "usa", "median tax"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("quantity", "median tax rate in Denmark", ["economics", "denmark", "median tax"]),
					for_choice: 1.0,
					references: []
				}]
			},
			%{
				poll: Poll.force_get("probability", "9/11 attacks were an inside job", ["usa", "9/11 attacks"]),
				references: []
			},
			%{
				poll: Poll.force_get("probability", "we should implement universal basic income", ["economics", "politics", "universal basic income"]),
				references: []
			},
			%{
				poll: Poll.force_get("quantity", "number of refugees EU should let inside", ["politics", "eu", "refugees"]),
				references: []
			},
			%{
				poll: Poll.force_get("probability", "genetically modified foods are safe", ["science", "biology", "gmo"]),
				references: []
			},
			%{
				poll: Poll.force_get("quantity", "year when we will have artificial general intelligence", ["science", "artificial intelligence"]),
				references: []
			},
			%{
				poll: Poll.force_get("quantity", "additional tax revenue in USD if recreational cannabis becomes legal in California", ["california", "politics", "economics"]),
				references: []
			}
		]
		if identity != nil and Application.get_env(:liquio, :admin_identity_ids) |> Enum.member?(identity.id) do
			approve_references(examples, identity)
		end
		examples = Enum.map(examples, fn(%{:poll => poll, :references => references}) ->
			Map.put(poll, :results, Result.calculate(poll, calculate_opts))
		end)
		render conn, "index.html", examples: Enum.shuffle(examples)
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