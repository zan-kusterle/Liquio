defmodule Democracy.PollOverviewController do
	use Democracy.Web, :controller
	
	def show(conn, _params) do
		render conn, "show.html"
	end
end