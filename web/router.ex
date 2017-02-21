defmodule Liquio.Router do
	use Liquio.Web, :router

	pipeline :api do
		plug :accepts, ["json"]
		plug :fetch_session

		plug Guardian.Plug.VerifySession
		plug Guardian.Plug.LoadResource
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
