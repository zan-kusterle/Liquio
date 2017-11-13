defmodule Liquio.Web.Router do
	use Liquio.Web, :router

	pipeline :api do
		plug :accepts, ["json"]
	end

	pipeline :browser do
		plug :accepts, ["html"]
		plug :fetch_session
	end
	
	scope "/api", Liquio.Web do
		pipe_through :api
		
		post "/identities/identifications", IdentityController, :set_identification
		resources "/identities", IdentityController, only: [:index, :show, :update, :delete]
		resources "/nodes", NodeController, only: [:index, :show, :update, :delete] do
			resources "/references", ReferenceController, only: [:show, :update, :delete]
		end
		get "/search/:id", NodeController, :search
	end

	scope "/", Liquio.Web do
		pipe_through :browser

		get "/page/:url", IndexController, :page
		get "/resource/*path", IndexController, :resource
		get "/", IndexController, :app
		get "/demo", IndexController, :app		
		get "/hub.html", IndexController, :app
		get "/*path", IndexController, :app
	end
end
