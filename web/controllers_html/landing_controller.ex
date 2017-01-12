defmodule Liquio.LandingController do
	use Liquio.Web, :controller

	plug :put_layout, "landing.html"
	
	def index(conn, _params) do
		examples = [
			%{
				choice_type: "probability",
				title: "Human Activity Is Causing Global Warming",
				fa_icon: "sun-o"
			}, %{
				choice_type: "probability",
				title: "Genetically Modified Foods Are Safe",
				fa_icon: "leaf"
			}, %{
				choice_type: "probability",
				title: "President Donald Trump's Approval Rating",
				fa_icon: "users"
			}, %{
				choice_type: "probability",
				title: "The Theory of Evolution Is a Fact",
				fa_icon: "hourglass-end",
			}, %{
				choice_type: "probability",
				title: "USA Should Legalize Recreational Cannabis",
				fa_icon: "bank"
			}, %{
				choice_type: "quantity",
				title: "Invention of General Artificial Intelligence Year",
				fa_icon: "bolt"
			}
		]

		calculation_opts = get_calculation_opts_from_conn(conn)
		nodes = Enum.map(examples, & Node.new(&1.title, &1.choice_type) |> Node.preload_results(calculation_opts) |> Map.put(:fa_icon, &1.fa_icon))

		render conn, "index.html", nodes: nodes
	end

	def learn(conn, _params) do
		render conn, "learn.html"
	end
end