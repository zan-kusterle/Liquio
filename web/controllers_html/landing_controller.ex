defmodule Liquio.LandingController do
	use Liquio.Web, :controller

	plug :put_layout, "landing.html"
	
	def index(conn, _params) do
		examples = [
			%{
				choice_type: "probability",
				title: "Human Activity Is Causing Global Warming",
				topics: ["science", "nature", "global warming"],
				fa_icon: "sun-o",
				references: [%{
					choice_type: "time_quantity",
					title: "Earth Sea Level in cm With 0 at Year 1900",
					topics: ["science", "nature", "global warming"],
					for_choice: 1.0,
					references: []
				}, %{
					choice_type: "time_quantity",
					title: "Earth Temperature in ℃",
					topics: ["science", "nature", "global warming"],
					for_choice: 1.0,
					references: []
				}, %{
					choice_type: "time_quantity",
					title: "Earth Ocean Temperature in ℃",
					topics: ["science", "nature", "global warming"],
					for_choice: 1.0,
					references: []
				}, %{
					choice_type: "time_quantity",
					title: "Earth Ice Volume Yearly Differences in km³",
					topics: ["science", "nature", "global warming"],
					for_choice: 1.0,
					references: []
				}, %{
					choice_type: "time_quantity",
					title: "Earth Surface Ocean Waters Acidity in pH",
					topics: ["science", "nature", "global warming"],
					for_choice: 1.0,
					references: []
				}, %{
					choice_type: "probability",
					title: "Glaciers Are Retreating Almost Everywhere Around the World",
					topics: ["science", "nature", "global warming"],
					for_choice: 1.0,
					references: []
				}, %{
					choice_type: "probability",
					title: "Not Enough Earth Temperature Historical Data Available to Know the Cause of Global Warming",
					topics: ["science", "nature", "global warming"],
					for_choice: 0.0,
					references: []
				}, %{
					choice_type: "probability",
					title: "Climate Models Used to Model Global Warming Are Proven to Be Unreliable",
					topics: ["science", "nature", "global warming"],
					for_choice: 0.0,
					references: []
				}, %{
					choice_type: "probability",
					title: "Variations in Climate Are Just a Part of Natural Cycles",
					topics: ["science", "nature", "global warming"],
					for_choice: 0.0,
					references: []
				}]
			}, %{
				choice_type: "probability",
				title: "Genetically Modified Foods Are Safe",
				topics: ["science", "biology", "gmo"],
				fa_icon: "leaf",
				references: [%{
					choice_type: "probability",
					title: "DNA From GM Crops Can Be Transferred Into Humans Who Eat Them",
					topics: ["science", "nature", "gmo"],
					for_choice: 0.0,
					references: [%{
						choice_type: "probability",
						title: "2013: Complete Genes May Pass from Food to Human Blood by Sándor Spisák, Norbert Solymosi, Péter Ittzés, András Bodor, Dániel Kondor, Gábor Vattay, Barbara K. Barták, Ferenc Sipos, Orsolya Galamb, Zsolt Tulassay, Zoltán Szállási, Simon Rasmussen, Thomas Sicheritz-Ponten, Søren Brunak, Béla Molnár and István Csabai. Is this article credible?",
						topics: ["science", "nature", "gmo"],
						for_choice: 1.0,
						references: []
					}]
				}, %{
					choice_type: "probability",
					title: "GMOs Cause Gluten Disorders That Affect 18 Million Americans",
					topics: ["science", "nature", "gmo"],
					for_choice: 0.0,
					references: [%{
						choice_type: "probability",
						title: "2013: 'GMOs Linked to Gluten Disorders Plaguing 18 million Americans - Report' by RT. Is this article credible?",
						topics: ["science", "nature", "gmo"],
						for_choice: 1.0,
						references: []
					}]
				}, %{
					choice_type: "probability",
					title: "GM Corn Causes Tumors in Rats",
					topics: ["science", "nature", "gmo"],
					for_choice: 0.0,
					references: [%{
						choice_type: "probability",
						title: "2012: Long Term Toxicity of a Roundup Herbicide and a Roundup-Tolerant Genetically Modified Maize by Gilles-Eric Séralini, Emilie Clair, Robin Mesnage, Steeve Gress,  Nicolas Defarge, Manuela Malatesta, Didier Hennequin and Joël Spiroux de Vendômois. Is this article credible?",
						topics: ["science", "nature", "gmo"],
						for_choice: 1.0,
						references: []
					}]
				}, %{
					choice_type: "probability",
					title: "Glyphosate Is Safe For Human Consumption",
					topics: ["science", "nature", "gmo"],
					for_choice: 1.0,
					references: [%{
						choice_type: "probability",
						title: "Glyphosate Induces Human Breast Cancer Cells Growth Via Estrogen Receptors",
						topics: ["science", "nature", "gmo"],
						for_choice: 0.0,
						references: [%{
							choice_type: "probability",
							title: "2013: Glyphosate Induces Human Breast Cancer Cells Growth Via Estrogen Receptors by Thongprakaisang S1, Thiantanawat A, Rangkadilok N, Suriyo T and Satayavivad J. Is this article credible?",
							topics: ["science", "nature", "gmo"],
							for_choice: 1.0,
							references: []
						}]
					}, %{
						choice_type: "probability",
						title: "Glyphosate Causes Birth Defects",
						topics: ["science", "nature", "gmo"],
						for_choice: 0.0,
						references: [%{
							choice_type: "probability",
							title: "2010: Glyphosate-Based Herbicides Produce Teratogenic Effects on Vertebrates by Impairing Retinoic Acid Signaling by Alejandra Paganelli, Victoria Gnazzo, Helena Acosta, Silvia L. López and Andrés E. Carrasco. Is this article credible?",
							topics: ["science", "nature", "gmo"],
							for_choice: 1.0,
							references: []
						}]
					}, %{
						choice_type: "probability",
						title: "Glyphosate Causes Autism",
						topics: ["science", "nature", "gmo"],
						for_choice: 0.0,
						references: [%{
							choice_type: "probability",
							title: "2013: Glyphosate’s Suppression of Cytochrome P450 Enzymes and Amino Acid Biosynthesis by the Gut Microbiome: Pathways to Modern Diseases by Anthony Samsel and Stephanie Seneff. Is this article credible?",
							topics: ["science", "nature", "gmo"],
							for_choice: 1.0,
							references: []
						}]
					}, %{
						choice_type: "probability",
						title: "Glyphosate Causes Parkinson's Disease",
						topics: ["science", "nature", "gmo"],
						for_choice: 0.0,
						references: [%{
							choice_type: "probability",
							title: "2013: Glyphosate’s Suppression of Cytochrome P450 Enzymes and Amino Acid Biosynthesis by the Gut Microbiome: Pathways to Modern Diseases by Anthony Samsel and Stephanie Seneff. Is this article credible?",
							topics: ["science", "nature", "gmo"],
							for_choice: 1.0,
							references: []
						}]
					}, %{
						choice_type: "probability",
						title: "Glyphosate Causes Alzheimer's Disease",
						topics: ["science", "nature", "gmo"],
						for_choice: 0.0,
						references: [%{
							choice_type: "probability",
							title: "2013: Glyphosate’s Suppression of Cytochrome P450 Enzymes and Amino Acid Biosynthesis by the Gut Microbiome: Pathways to Modern Diseases by Anthony Samsel and Stephanie Seneff. Is this article credible?",
							topics: ["science", "nature", "gmo"],
							for_choice: 1.0,
							references: []
						}]
					}, %{
						choice_type: "probability",
						title: "Chronically Ill Humans Have Higher Glyphosate Levels Than Healthy Humans",
						topics: ["science", "nature", "gmo"],
						for_choice: 0.0,
						references: [%{
							choice_type: "probability",
							title: "2014: Detection of Glyphosate Residues in Animals and Humans by Monika Krüger, Philipp Schledorn, Wieland Schrödl, Hans-Wolfgang Hoppe, Walburga Lutz and Awad A. Shehata. Is this credible?",
							topics: ["science", "nature", "gmo"],
							for_choice: 1.0,
							references: []
						}]
					}]
				}, %{
					choice_type: "probability",
					title: "GM Food Cause Severe Stomach Inflammation and Enlarged Uteri in Pigs",
					topics: ["science", "nature", "gmo"],
					for_choice: 0.0,
					references: [%{
						choice_type: "probability",
						title: "2013: A Long-Term Toxicology Study on Pigs Fed a Combined Genetically Modified (GM) Soy and GM Maize Diet by Judy A. Carman, Howard R. Vlieger, Larry J. Ver Steeg, Verlyn E. Sneller, Garth W. Robinson, Catherine A. Clinch-Jones, Julie I. Haynes and John W. Edwards. Is this study credible?",
						topics: ["science", "nature", "gmo"],
						for_choice: 1.0,
						references: []
					}]
				}, %{
					choice_type: "probability",
					title: "GMO Risk Assessment Is Based on Little Scientific Evidence in the Sense That the Testing Methods Recommended Are Not Adequate to Ensure Safety",
					topics: ["science", "nature", "gmo"],
					for_choice: 0.0,
					references: [%{
						choice_type: "probability",
						title: "2004: Risk Assessment of Genetically Modified Crops For Nutrition and Health by Javier A Magaña-Gómez and Ana M Calderón de la Barca. Is this article credible?",
						topics: ["science", "nature", "gmo"],
						for_choice: 1.0,
						references: []
					}, %{
						choice_type: "probability",
						title: "2004: Reese W, Schubert D — Safety Testing and Regulation of Genetically Engineered Foods. Is this book legit?",
						topics: ["science", "nature", "gmo"],
						for_choice: 1.0,
						references: []
					}, %{
						choice_type: "probability",
						title: "2002: Schubert D — A Different Perspective on GM food. Is this book legit?",
						topics: ["science", "nature", "gmo"],
						for_choice: 1.0,
						references: []
					}]
				}]
			}, %{
				choice_type: "probability",
				title: "President Donald Trump's Approval Rating",
				topics: ["politics", "usa", "donald trump"],
				fa_icon: "users",
				references: [%{
					choice_type: "quantity",
					title: "Number of Refugees EU Should Let Inside",
					topics: ["politics", "eu", "refugees"],
					fa_icon: "question",
					for_choice: 0.5,
					references: []
				}]
			}, %{
				choice_type: "probability",
				title: "The Theory of Evolution Is a Fact",
				topics: ["science", "biology", "evolution"],
				fa_icon: "hourglass-end",
				references: []
			}, %{
				choice_type: "probability",
				title: "USA Should Legalize Recreational Cannabis",
				topics: ["california", "politics", "economics"],
				fa_icon: "bank",
				references: [%{
					choice_type: "quantity",
					title: "Additional Tax Revenue in USD If Recreational Cannabis Becomes Legal in California",
					topics: ["california", "politics", "economics"],
					fa_icon: "bank",
					for_choice: 1.0,
					references: []
				}, %{
					choice_type: "time_quantity",
					title: "Number of Traffic Fatalities by Year in the USA",
					topics: ["statistics", "usa"],
					fa_icon: "road",
					for_choice: 1.0,
					references: []
				}]
			}, %{
				choice_type: "quantity",
				title: "Invention of General Artificial Intelligence Year",
				topics: ["science", "artificial intelligence"],
				fa_icon: "bolt",
				references: []
			}
		]
		polls = %{
			:not_the_best_idea => Poll.force_get("probability", "Vanilla Ice Cream Flavor Rating")
		}

		calculate_opts = get_calculation_opts_from_conn(conn)
		identity = Guardian.Plug.current_resource(conn)
		if identity != nil and Application.get_env(:liquio, :admin_identity_ids) |> Enum.member?(identity.id) do
			traverse_examples(examples, identity)
		end
		examples = Enum.map(examples, fn(example) ->
			poll = Poll.force_get(example.choice_type, example.title)
			poll
			|> Map.put(:fa_icon, example.fa_icon)
			|> Map.put(:topics, example.topics)
			|> Map.put(:results, Poll.calculate(poll, calculate_opts))
			|> Map.put(:num_references, Enum.count(example.references))
		end)

		render conn, "index.html", examples: examples, polls: polls
	end

	def learn(conn, _params) do
		render conn, "learn.html"
	end

	def traverse_examples(examples, identity) do
		Enum.flat_map(examples, fn(example) ->
			poll = Poll.force_get(example.choice_type, example.title)
			Enum.each(example.topics, &(cast_topic_vote(poll, &1, identity)))
			Enum.each(example.references, &(cast_approve_vote(poll, &1, identity)))
			traverse_examples(example.references, identity)
		end)
	end

	def cast_topic_vote(poll, topic_name, identity) do
		topic = Topic.get(topic_name, poll)
		|> Repo.preload([:relevance_poll])

		current_vote = Vote.current_by(topic.relevance_poll, identity)
		if current_vote == nil do
			Vote.set(topic.relevance_poll, identity, %{:main => 1.0})
		end
	end

	def cast_approve_vote(poll, example_reference, identity) do
		reference_poll = Poll.force_get(example_reference.choice_type, example_reference.title)
		reference = Reference.get(poll, reference_poll)
		|> Repo.preload([:for_choice_poll])

		current_vote = Vote.current_by(reference.for_choice_poll, identity)
		if current_vote == nil do
			Vote.set(reference.for_choice_poll, identity, %{:main => example_reference.for_choice})
		end
	end
end