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

		scope "/login" do
			resources "/", LoginController, only: [:create, :show, :delete]
			get "/:provider", LoginController, :request
			get "/:provider/callback", LoginController, :callback
			post "/:provider/callback", LoginController, :callback
		end
		get "/logout", LoginController, :delete
		resources "/identities", IdentityController, only: [:index, :create, :show, :update, :delete]
		resources "/nodes", NodeController, only: [:index, :show, :update, :delete] do
			resources "/references", ReferenceController, only: [:show, :update, :delete]
		end
		get "/search/:id", NodeController, :search
	end

	scope "/", Liquio.Web do
		pipe_through :browser

		get "/*path", IndexController, :app
	end
end
