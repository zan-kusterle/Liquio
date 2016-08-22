defmodule Liquio.LandingController do
	use Liquio.Web, :controller

	alias Liquio.Poll
	
	plug :put_layout, "landing.html"

	def index(conn, _params) do
		examples = %{
			:facts => [
				Poll.force_get("probability", "global warming is caused by human activity", ["science", "nature", "global warming"]),
				Poll.force_get("quantity", "sea level rise since year 1900 in centimeters", ["science", "nature", "global warming"]),
				Poll.force_get("probability", "9/11 attacks were an inside job", ["usa", "9/11 attacks"]),
				Poll.force_get("quantity", "median tax rate in the USA", ["economics", "usa", "median tax"])
			],
			:opinions => [
				Poll.force_get("probability", "we should implement universal basic income", ["economics", "politics", "universal basic income"]),
				Poll.force_get("quantity", "number of refugees EU should let inside", ["politics", "eu", "refugees"]),
				Poll.force_get("quantity", "the ideal age for children to start going to school", ["education", "children"]),
				Poll.force_get("probability", "genetically modified foods are safe", ["science", "biology", "gmo"])
			],
			:predictions => [
				Poll.force_get("quantity", "year when we will have artificial general intelligence", ["science", "artificial intelligence"]),
				Poll.force_get("quantity", "additional tax revenue in USD if recreational cannabis becomes legal in California", ["california", "politics", "economics"]),
				Poll.force_get("quantity", "year when we will completely cure cancer", ["science", "medicine", "cancer"]),
				Poll.force_get("quantity", "difference in sea level from year 2000 until year 2050 in centimeters", ["science", "nature", "global warming"])
			]
		}
		render conn, "index.html", examples: examples
	end
end