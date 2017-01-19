defmodule Liquio.LandingController do
	use Liquio.Web, :controller

	plug :put_layout, "landing.html"

	def learn(conn, _params) do
		render conn, "learn.html"
	end
end