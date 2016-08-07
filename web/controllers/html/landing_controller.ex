defmodule Liquio.LandingController do
	use Liquio.Web, :controller
	
	plug :put_layout, "landing.html"

	def index(conn, _params) do
		render conn, "index.html"
	end
end