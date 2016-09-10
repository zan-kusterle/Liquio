defmodule Liquio.LandingController do
	use Liquio.Web, :controller

	plug :put_layout, "landing.html"

	def index(conn, _params) do
		examples = [
			%{
				poll: Poll.force_get("probability", "global warming is caused by human activity", ["science", "nature", "global warming"])
				|> Map.put(:fa_icon, "sun-o"),
				references: [%{
					poll: Poll.force_get("time_quantity", "earth sea level in cm with zero at year 1900", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "earth temperature in ℃", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "earth ocean temperature in ℃", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "earth ice volume yearly differences in km³", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "earth surface ocean waters acidity in pH", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("probability", "glaciers are retreating almost everywhere around the world", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("probability", "not enough earth temperature historical data available to know the cause of global warming", ["science", "nature", "global warming"]),
					for_choice: 0.0,
					references: []
				}, %{
					poll: Poll.force_get("probability", "climate models used to model global warming are proven to be unreliable", ["science", "nature", "global warming"]),
					for_choice: 0.0,
					references: []
				}, %{
					poll: Poll.force_get("probability", "variations in climate are just a part of natural cycles", ["science", "nature", "global warming"]),
					for_choice: 0.0,
					references: []
				}]
			}, %{
				poll: Poll.force_get("probability", "genetically modified foods are dangerous", ["science", "biology", "gmo"])
				|> Map.put(:fa_icon, "leaf"),
				references: [%{
					poll: Poll.force_get("probability", "Multiple Toxins From GMOs Detected In Maternal and Fetal Blood", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "2011: Maternal and fetal exposure to pesticides associated to genetically modified foods in Eastern Townships of Quebec, Canada by Aziz Aris and Samuel Leblanc. Is this article credible?", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}, %{
					poll: Poll.force_get("probability", "DNA From Genetically Modified Crops Can Be Transferred Into Humans Who Eat Them", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "2013: Complete Genes May Pass from Food to Human Blood by Sándor Spisák, Norbert Solymosi, Péter Ittzés, András Bodor, Dániel Kondor, Gábor Vattay, Barbara K. Barták, Ferenc Sipos, Orsolya Galamb, Zsolt Tulassay, Zoltán Szállási, Simon Rasmussen, Thomas Sicheritz-Ponten, Søren Brunak, Béla Molnár and István Csabai. Is this article credible?", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}, %{
					poll: Poll.force_get("probability", "Study Links GMOs To Gluten Disorders That Affect 18 Million Americans", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "2013: GMOs linked to gluten disorders plaguing 18 million Americans - report by RT. Is this article credible?", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}, %{
					poll: Poll.force_get("probability", "Study Links Genetically Modified Corn to Rat Tumors", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "2012: Long term toxicity of a Roundup herbicide and a Roundup-tolerant genetically modified maize by Gilles-Eric Séralini, Emilie Clair, Robin Mesnage, Steeve Gress,  Nicolas Defarge, Manuela Malatesta, Didier Hennequin, Joël Spiroux de Vendômois. Is this article credible?", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}, %{
					poll: Poll.force_get("probability", "variations in climate are just a part of natural cycles", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "variations in climate are just a part of natural cycles", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}, %{
					poll: Poll.force_get("probability", "variations in climate are just a part of natural cycles", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "variations in climate are just a part of natural cycles", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}, %{
					poll: Poll.force_get("probability", "variations in climate are just a part of natural cycles", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "variations in climate are just a part of natural cycles", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}, %{
					poll: Poll.force_get("probability", "variations in climate are just a part of natural cycles", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "variations in climate are just a part of natural cycles", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}, %{
					poll: Poll.force_get("probability", "variations in climate are just a part of natural cycles", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "variations in climate are just a part of natural cycles", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}]
			}, %{
				poll: Poll.force_get("quantity", "number of refugees EU should let inside", ["politics", "eu", "refugees"])
				|> Map.put(:fa_icon, "question"),
				references: []
			}, %{
				poll: Poll.force_get("time_quantity", "number of yearly traffic fatalities in the USA", ["statistics", "usa"])
				|> Map.put(:fa_icon, "road"),
				references: []
			}, %{
				poll: Poll.force_get("probability", "the theory of evolution is true", ["science", "biology", "evolution"])
				|> Map.put(:fa_icon, "hourglass-end"),
				references: []
			}, %{
				poll: Poll.force_get("quantity", "year when we will have artificial general intelligence", ["science", "artificial intelligence"])
				|> Map.put(:fa_icon, "bolt"),
				references: []
			}, %{
				poll: Poll.force_get("quantity", "additional tax revenue in USD if recreational cannabis becomes legal in California", ["california", "politics", "economics"])
				|> Map.put(:fa_icon, "bank"),
				references: []
			}, %{
				poll: Poll.force_get("probability", "2013: Glyphosate’s Suppression of Cytochrome P450 Enzymes and Amino Acid Biosynthesis by the Gut Microbiome: Pathways to Modern Diseases by Anthony Samsel & Stephanie Seneff. Is this article credible?", ["california", "politics", "economics"])
				|> Map.put(:fa_icon, "bank"),
				references: []
			}
			
		]
		polls = %{
			:not_the_best_idea => Poll.force_get("probability", "vanilla ice cream flavor rating", ["joke"])
		}

		calculate_opts = get_calculation_opts_from_conn(conn)
		identity = Guardian.Plug.current_resource(conn)
		if identity != nil and Application.get_env(:liquio, :admin_identity_ids) |> Enum.member?(identity.id) do
			approve_references(examples, identity)
		end
		examples = Enum.map(examples, fn(example) ->
			example.poll
			|> Map.put(:results, Poll.calculate(example.poll, calculate_opts))
			|> Map.put(:num_references, Enum.count(example.references))
		end)

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
			Vote.set(reference.approval_poll, identity, %{:main => 1.0})
		end
	end
end