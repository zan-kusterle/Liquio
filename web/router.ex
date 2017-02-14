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

		plug Guardian.Plug.VerifySession
		plug Guardian.Plug.LoadResource
	end

	scope "/", Liquio do
		pipe_through :browser

		get "/link", LandingController, :learn

		resources "/login", HtmlLoginController, only: [:index, :show, :create]
		get "/logout", HtmlLoginController, :delete

		post "/identities/me/preferences", HtmlIdentityController, :update
		resources "/identities", HtmlIdentityController, only: [:create, :show] do
			resources "/delegations", HtmlDelegationController, only: [:create]
		end

		resources "/", HtmlNodeController, only: [:show, :create] do
			resources "/references", HtmlReferenceController, only: [:show, :create]
		end

		get "/", HtmlExploreController, :index
		get "/search", HtmlExploreController, :search
	end

	scope "/", Liquio do
		pipe_through :embed

		get "/:html_node_id/embed", HtmlNodeController, :embed
	end
	
	scope "/api", Liquio do
		pipe_through :api

		resources "/login", LoginController, only: [:create, :show, :delete]

		resources "/identities", IdentityController, only: [:index, :create, :show] do
			resources "/delegations", DelegationController, only: [:create, :delete], singleton: true
		end
		
		resources "/nodes", NodeController, only: [:index, :show] do
			resources "/votes", VoteController, only: [:create, :delete], singleton: true
			resources "/references", ReferenceController, only: [:show] do
				resources "/votes", ReferenceVoteController, only: [:create, :delete], singleton: true
			end
		end

		get "/search", SearchController, :index
	end
end
