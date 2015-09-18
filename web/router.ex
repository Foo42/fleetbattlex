defmodule Fleetbattlex.Router do
  use Fleetbattlex.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Fleetbattlex do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/", Fleetbattlex do
    pipe_through :api 

    resources "fleets", FleetController, only: [:index, :show] do
      resources "ships", ShipController, only: [:index, :show]
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", Fleetbattlex do
  #   pipe_through :api
  # end
end
