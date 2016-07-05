defmodule Democracy.Router do
	use Democracy.Web, :router

	pipeline :browser do
		plug :accepts, ["html"]
		plug :fetch_session
		plug :fetch_flash
		plug :protect_from_forgery
		plug :put_secure_browser_headers
	end

	pipeline :api do
		plug :accepts, ["json"]
		plug :fetch_session

		plug Guardian.Plug.VerifyHeader
		plug Guardian.Plug.LoadResource
	end

	scope "/", Democracy do
		pipe_through :browser

		get "/", LandingController, :index
		resources "/polls", PollOverviewController, only: [:show] do
			get "/details", PollOverviewController, :details
		end
	end

	scope "/api", Democracy do
		pipe_through :api

		resources "/login", LoginController, only: [:create, :delete]

		resources "/identities", IdentityController, only: [:index, :create, :show] do
			resources "/delegations", DelegationController, only: [:index, :create, :show, :delete]
		end
		
		resources "/polls", PollController, only: [:create, :show] do
			resources "/votes", VoteController, only: [:index, :create, :show]
			resources "/votes", VoteController, only: [:delete], singleton: true
			get "/contributions", PollController, :contributions
			resources "/references", ReferenceController, only: [:index, :create, :show]
		end

		get "/search", SearchController, :index
	end
end
