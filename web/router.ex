defmodule Democracy.Router do
	use Democracy.Web, :router

	pipeline :browser do
		plug :accepts, ["html"]
		plug :fetch_session
		plug :fetch_flash
		plug :protect_from_forgery
		plug :put_secure_browser_headers
		plug Guardian.Plug.VerifySession
		plug Guardian.Plug.LoadResource
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

		resources "/login", HtmlLoginController, only: [:index, :create]
		get "/logout", HtmlLoginController, :delete

		resources "/identities", HtmlIdentityController, only: [:show, :new, :create] do
			resources "/delegations", HtmlDelegationController, only: [:create]
		end

		resources "/polls", HtmlPollController, only: [:show, :new, :create] do
			get "/details", HtmlPollController, :details
			resources "/vote", HtmlVoteController, only: [:index, :create, :delete]
			resources "/references", HtmlReferenceController, only: [:index, :show]
			get "/embed", HtmlPollController, :embed
		end

		get "/explore", HtmlExploreController, :index
		resources "/topics", HtmlExploreController, only: [:show]
		get "/search", HtmlExploreController, :search
	end

	scope "/api", Democracy do
		pipe_through :api

		resources "/login", LoginController, only: [:create, :delete]

		resources "/identities", IdentityController, only: [:index, :create, :show] do
			resources "/delegations", DelegationController, only: [:index, :show]
			resources "/delegations", DelegationController, only: [:create, :delete], singleton: true
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
