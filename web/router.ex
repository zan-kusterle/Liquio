defmodule Democracy.Router do
	use Democracy.Web, :router

	pipeline :api do
		plug :accepts, ["json"]
		plug :fetch_session

		plug Guardian.Plug.VerifyHeader
		plug Guardian.Plug.LoadResource
	end

	scope "/", Democracy do
		pipe_through :api

		resources "/login", LoginController, only: [:create, :delete]

		resources "/identities", IdentityController, only: [:index, :create, :show] do
			resources "/delegations", DelegationController, only: [:index, :create, :show, :delete]
		end

		resources "/polls", PollController, only: [:create, :show] do
			resources "/votes", VoteController, only: [:index, :create]
			resources "/references", ReferenceController, only: [:index, :create]
			get "/results", PollController, :results
		end		
	end
end
