defmodule Democracy.LandingController do
	use Democracy.Web, :controller
	
	def index(conn, _params) do
		render conn, "index.html"
	end
end