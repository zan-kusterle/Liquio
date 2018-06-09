defmodule Liquio.Web.Router do
  use Liquio.Web, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/api", Liquio.Web do
    pipe_through(:api)

    get("/nodes/:title", NodeController, :show)
    get("/search/:query", SearchController, :show)
  end

  scope "/", Liquio.Web do
    pipe_through(:browser)

    get("/", IndexController, :index)
  end
end
