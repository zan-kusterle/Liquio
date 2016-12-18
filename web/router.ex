defmodule Liquio.Router do
	use Liquio.Web, :router

	pipeline :browser do
		plug :accepts, ["html"]
		plug :fetch_session
		plug :fetch_flash
		plug :protect_from_forgery
		plug :put_secure_browser_headers
		
		plug Guardian.Plug.VerifySession
		plug Guardian.Plug.LoadResource

		plug Liquio.Plugs.MinifyHtml
	end

	pipeline :embed do
		plug :accepts, ["html"]
		plug :fetch_session

		plug Guardian.Plug.VerifySession
		plug Guardian.Plug.LoadResource

		plug Liquio.Plugs.MinifyHtml
	end

	pipeline :api do
		plug :accepts, ["json"]
		plug :fetch_session

		plug Guardian.Plug.VerifyHeader
		plug Guardian.Plug.LoadResource
	end

	scope "/", Liquio do
		pipe_through :browser

		get "/", LandingController, :index

		resources "/login", HtmlLoginController, only: [:index, :show, :create]
		get "/logout", HtmlLoginController, :delete

		resources "/identities", HtmlIdentityController, only: [:create, :show] do
			resources "/delegations", HtmlDelegationController, only: [:create]
		end
		post "/identities/me/preferences", HtmlIdentityController, :update

		resources "/polls", HtmlPollController, only: [:create, :show] do
			resources "/vote", HtmlVoteController, only: [:create, :delete]
			resources "/references", HtmlReferenceController, only: [:index, :show]
		end

		get "/explore/:sort", HtmlExploreController, :index
		resources "/topics", HtmlExploreController, only: [:show] do
			get "/:sort/embed", HtmlExploreController, :show_embed
			get "/:sort", HtmlExploreController, :show
			get "/polls/:poll_id", HtmlTopicController, :reference
		end
		get "/search", HtmlExploreController, :search
	end

	scope "/", Liquio do
		pipe_through :embed

		get "/polls/:html_poll_id/embed", HtmlPollController, :embed
	end
	
	scope "/api", Liquio do
		pipe_through :api

		resources "/login", LoginController, only: [:create, :delete]

		resources "/identities", IdentityController, only: [:index, :create, :show] do
			resources "/delegations", DelegationController, only: [:index, :show]
			resources "/delegations", DelegationController, only: [:create, :delete], singleton: true
		end
		
		resources "/polls", PollController, only: [:create, :show] do
			resources "/votes", VoteController, only: [:create, :index, :show]
			resources "/votes", VoteController, only: [:delete], singleton: true
			get "/contributions", PollController, :contributions
			resources "/references", ReferenceController, only: [:create, :index, :show]
		end

		get "/search", SearchController, :index
	end
end
