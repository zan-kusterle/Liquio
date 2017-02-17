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

		get "/login", HtmlLoginController, :show
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

		get "/search/:id", NodeController, :search
	end
end
