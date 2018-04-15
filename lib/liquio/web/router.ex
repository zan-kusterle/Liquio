defmodule Liquio.Web.Router do
	use Liquio.Web, :router

	pipeline :api do
		plug :accepts, ["json"]
	end

	pipeline :browser do
		plug :accepts, ["html"]
	end
	
	scope "/api", Liquio.Web do
		pipe_through :api

		get "/nodes/:title", NodeController, :show
		get "/search/:query", NodeController, :search
	end

	scope "/", Liquio.Web do
		pipe_through :browser

		get "/", IndexController, :app
		get "/demo", IndexController, :app		
		get "/*path", IndexController, :app
	end
end
