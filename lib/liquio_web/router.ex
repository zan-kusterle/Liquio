defmodule LiquioWeb.Router do
  use LiquioWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/api", LiquioWeb do
    pipe_through(:api)

    get("/nodes", NodeController, :index)
    get("/search/:query", SearchController, :show)
  end

  scope "/", LiquioWeb do
    pipe_through(:browser)

    forward "/", Plugs.StaticPlug
  end
end
