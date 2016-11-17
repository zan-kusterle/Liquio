defmodule Liquio.LandingController do
	use Liquio.Web, :controller

	plug :put_layout, "landing.html"

	def index(conn, _params) do
		examples = [
			%{
				poll: Poll.force_get("probability", "Human Activity Is Causing Global Warming", ["science", "nature", "global warming"])
				|> Map.put(:fa_icon, "sun-o"),
				references: [%{
					poll: Poll.force_get("time_quantity", "Earth Sea Level in cm With 0 at Year 1900", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "Earth Temperature in ℃", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "Earth Ocean Temperature in ℃", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "Earth Ice Volume Yearly Differences in km³", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "Earth Surface Ocean Waters Acidity in pH", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("probability", "Glaciers Are Retreating Almost Everywhere Around the World", ["science", "nature", "global warming"]),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("probability", "Not Enough Earth Temperature Historical Data Available to Know the Cause of Global Warming", ["science", "nature", "global warming"]),
					for_choice: 0.0,
					references: []
				}, %{
					poll: Poll.force_get("probability", "Climate Models Used to Model Global Warming Are Proven to Be Unreliable", ["science", "nature", "global warming"]),
					for_choice: 0.0,
					references: []
				}, %{
					poll: Poll.force_get("probability", "Variations in Climate Are Just a Part of Natural Cycles", ["science", "nature", "global warming"]),
					for_choice: 0.0,
					references: []
				}]
			}, %{
				poll: Poll.force_get("probability", "Genetically Modified Foods Are Safe", ["science", "biology", "gmo"])
				|> Map.put(:fa_icon, "leaf"),
				references: [%{
					poll: Poll.force_get("probability", "Multiple Toxins From GMOs Detected In Maternal and Fetal Blood", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "2011: Maternal and Fetal Exposure to Pesticides Associated to Genetically Modified Foods in Eastern Townships of Quebec, Canada by Aziz Aris and Samuel Leblanc. Is this article credible?", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}, %{
					poll: Poll.force_get("probability", "DNA From GM Crops Can Be Transferred Into Humans Who Eat Them", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "2013: Complete Genes May Pass from Food to Human Blood by Sándor Spisák, Norbert Solymosi, Péter Ittzés, András Bodor, Dániel Kondor, Gábor Vattay, Barbara K. Barták, Ferenc Sipos, Orsolya Galamb, Zsolt Tulassay, Zoltán Szállási, Simon Rasmussen, Thomas Sicheritz-Ponten, Søren Brunak, Béla Molnár and István Csabai. Is this article credible?", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}, %{
					poll: Poll.force_get("probability", "GMOs Cause Gluten Disorders That Affect 18 Million Americans", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "2013: 'GMOs Linked to Gluten Disorders Plaguing 18 million Americans - Report' by RT. Is this article credible?", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}, %{
					poll: Poll.force_get("probability", "GM Corn Causes Tumors in Rats", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "2012: Long Term Toxicity of a Roundup Herbicide and a Roundup-Tolerant Genetically Modified Maize by Gilles-Eric Séralini, Emilie Clair, Robin Mesnage, Steeve Gress,  Nicolas Defarge, Manuela Malatesta, Didier Hennequin and Joël Spiroux de Vendômois. Is this article credible?", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}, %{
					poll: Poll.force_get("probability", "Glyphosate Is Safe For Human Consumption", ["science", "nature", "gmo"]),
					for_choice: 1.0,
					references: [%{
						poll: Poll.force_get("probability", "Glyphosate Induces Human Breast Cancer Cells Growth Via Estrogen Receptors", ["science", "nature", "gmo"]),
						for_choice: 0.0,
						references: [%{
							poll: Poll.force_get("probability", "2013: Glyphosate Induces Human Breast Cancer Cells Growth Via Estrogen Receptors by Thongprakaisang S1, Thiantanawat A, Rangkadilok N, Suriyo T and Satayavivad J. Is this article credible?", ["science", "nature", "gmo"]),
							for_choice: 1.0,
							references: []
						}]
					}, %{
						poll: Poll.force_get("probability", "Glyphosate Causes Birth Defects", ["science", "nature", "gmo"]),
						for_choice: 0.0,
						references: [%{
							poll: Poll.force_get("probability", "2010: Glyphosate-Based Herbicides Produce Teratogenic Effects on Vertebrates by Impairing Retinoic Acid Signaling by Alejandra Paganelli, Victoria Gnazzo, Helena Acosta, Silvia L. López and Andrés E. Carrasco. Is this article credible?", ["science", "nature", "gmo"]),
							for_choice: 1.0,
							references: []
						}]
					}, %{
						poll: Poll.force_get("probability", "Glyphosate Causes Autism", ["science", "nature", "gmo"]),
						for_choice: 0.0,
						references: [%{
							poll: Poll.force_get("probability", "2013: Glyphosate’s Suppression of Cytochrome P450 Enzymes and Amino Acid Biosynthesis by the Gut Microbiome: Pathways to Modern Diseases by Anthony Samsel and Stephanie Seneff. Is this article credible?", ["science", "nature", "gmo"]),
							for_choice: 1.0,
							references: []
						}]
					}, %{
						poll: Poll.force_get("probability", "Glyphosate Causes Parkinson's", ["science", "nature", "gmo"]),
						for_choice: 0.0,
						references: [%{
							poll: Poll.force_get("probability", "2013: Glyphosate’s Suppression of Cytochrome P450 Enzymes and Amino Acid Biosynthesis by the Gut Microbiome: Pathways to Modern Diseases by Anthony Samsel and Stephanie Seneff. Is this article credible?", ["science", "nature", "gmo"]),
							for_choice: 1.0,
							references: []
						}]
					}, %{
						poll: Poll.force_get("probability", "Glyphosate Causes Alzheimer's", ["science", "nature", "gmo"]),
						for_choice: 0.0,
						references: [%{
							poll: Poll.force_get("probability", "2013: Glyphosate’s Suppression of Cytochrome P450 Enzymes and Amino Acid Biosynthesis by the Gut Microbiome: Pathways to Modern Diseases by Anthony Samsel and Stephanie Seneff. Is this article credible?", ["science", "nature", "gmo"]),
							for_choice: 1.0,
							references: []
						}]
					}, %{
						poll: Poll.force_get("probability", "Chronically Ill Humans Have Higher Glyphosate Levels Than Healthy Humans", ["science", "nature", "gmo"]),
						for_choice: 0.0,
						references: [%{
							poll: Poll.force_get("probability", "2014: Detection of Glyphosate Residues in Animals and Humans by Monika Krüger, Philipp Schledorn, Wieland Schrödl, Hans-Wolfgang Hoppe, Walburga Lutz and Awad A. Shehata. Is this credible?", ["science", "nature", "gmo"]),
							for_choice: 1.0,
							references: []
						}]
					}]
				}, %{
					poll: Poll.force_get("probability", "GM Food Causes Severe Stomach Inflammation and Enlarged Uteri in Pigs", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "2013: A Long-Term Toxicology Study on Pigs Fed a Combined Genetically Modified (GM) Soy and GM Maize Diet by Judy A. Carman, Howard R. Vlieger, Larry J. Ver Steeg, Verlyn E. Sneller, Garth W. Robinson, Catherine A. Clinch-Jones, Julie I. Haynes and John W. Edwards. Is this study credible?", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}, %{
					poll: Poll.force_get("probability", "GMO Risk Assessment Is Based on Little Scientific Evidence in the Sense That the Testing Methods Recommended Are Not Adequate to Ensure Safety", ["science", "nature", "gmo"]),
					for_choice: 0.0,
					references: [%{
						poll: Poll.force_get("probability", "2004: Risk Assessment of Genetically Modified Crops For Nutrition and Health by Javier A Magaña-Gómez and Ana M Calderón de la Barca. Is this article credible?", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}, %{
						poll: Poll.force_get("probability", "2004: Reese W, Schubert D — Safety Testing and Regulation of Genetically Engineered Foods. Is this book legit?", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}, %{
						poll: Poll.force_get("probability", "2002: Schubert D — A Different Perspective on GM food. Is this book legit?", ["science", "nature", "gmo"]),
						for_choice: 1.0,
						references: []
					}]
				}]
			}, %{
				poll: Poll.force_get("probability", "President Donald Trump's Approval Rating", ["politics", "usa", "donald trump"])
				|> Map.put(:fa_icon, "users"),
				references: [%{
					poll: Poll.force_get("quantity", "Number of Refugees EU Should Let Inside", ["politics", "eu", "refugees"])
					|> Map.put(:fa_icon, "question"),
					for_choice: 0.5,
					references: []
				}]
			}, %{
				poll: Poll.force_get("probability", "The Theory of Evolution Is a Fact", ["science", "biology", "evolution"])
				|> Map.put(:fa_icon, "hourglass-end"),
				references: []
			}, %{
				poll: Poll.force_get("probability", "USA Government Should Legalize Recreational Cannabis", ["california", "politics", "economics"])
				|> Map.put(:fa_icon, "bank"),
				references: [%{
					poll: Poll.force_get("quantity", "Additional Tax Revenue in USD If Recreational Cannabis Becomes Legal in California", ["california", "politics", "economics"])
					|> Map.put(:fa_icon, "bank"),
					for_choice: 1.0,
					references: []
				}, %{
					poll: Poll.force_get("time_quantity", "Number of Traffic Fatalities by Year in the USA", ["statistics", "usa"])
					|> Map.put(:fa_icon, "road"),
					for_choice: 1.0,
					references: []
				}]
			}, %{
				poll: Poll.force_get("quantity", "Invention of General Artificial Intelligence Year", ["science", "artificial intelligence"])
				|> Map.put(:fa_icon, "bolt"),
				references: []
			}
		]
		polls = %{
			:not_the_best_idea => Poll.force_get("probability", "Vanilla Ice Cream Flavor Rating", ["joke"])
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