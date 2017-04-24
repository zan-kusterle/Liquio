defmodule Liquio.Web.Router do
	use Liquio.Web, :router

	pipeline :api do
		plug :accepts, ["json"]
		plug :fetch_session

		plug Guardian.Plug.VerifySession
		plug Guardian.Plug.LoadResource
	end

	pipeline :browser do
		plug :accepts, ["html"]
	end
	
	scope "/api", Liquio.Web do
		pipe_through :api

		resources "/login", LoginController, only: [:create, :show, :delete]
		get "/logout", LoginController, :delete
		resources "/identities", IdentityController, only: [:index, :create, :show, :create, :delete]
		resources "/nodes", NodeController, only: [:index, :show] do
			resources "/votes", VoteController, only: [:create, :delete], singleton: true
			resources "/references", ReferenceController, only: [:show] do
				resources "/votes", ReferenceVoteController, only: [:create, :delete], singleton: true
			end
		end
		get "/search/:id", NodeController, :search
	end

	scope "/", Liquio.Web do
		pipe_through :browser

		get "/*path", IndexController, :app
	end
end
