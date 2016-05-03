defmodule Democracy.Router do
  use Democracy.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    #plug :protect_from_forgery
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
    pipe_through :api

    get "/", PageController, :index
    resources "/session", SessionController, only: [:create, :delete]
    resources "/users", UserController, except: [:new, :edit, :index] do
        resources "/delegations", DelegationController, except: [:new, :edit]
    end

    get "/votes/cast", VoteController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", Democracy do
  #   pipe_through :api
  # end
end
